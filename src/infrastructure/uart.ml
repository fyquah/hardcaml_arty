open Base
open Hardcaml
open Signal

module Byte_with_valid = struct
  module Pre = struct
    include With_valid

    let t = 
      { valid = ("valid", 1)
      ; value = ("value", 8)
      }
    ;;
  end

  include Pre
  include Hardcaml.Interface.Make(Pre)
end

module Tx_state_machine = struct
  let create ~clock ~trigger (byte_with_valid : Signal.t Byte_with_valid.t) =
    let spec = Reg_spec.create ~clock () in
    let data =
      Signal.reg spec ~enable:(byte_with_valid.valid &: trigger)
        byte_with_valid.value
    in
    let busy =
      Signal.reg_fb spec ~enable:vdd ~w:1 (fun fb ->
          mux2 ((fb ==:. 0) &: byte_with_valid.valid &: trigger)
            vdd
            fb)
    in
    let ctr =
      Signal.reg_fb spec ~enable:vdd ~w:3 (fun fb ->
          mux2 ((busy ==:. 1) &: trigger)
            (fb +:. 1)
            (zero 3))
    in
    let data =
      (* Parity bit ? *)
      mux ctr (bits_lsb data)
    in
    mux2 busy
      data
      (mux2 byte_with_valid.valid gnd vdd)
  ;;
end

module Rx_state_machine = struct
  let rec shift_register ~enable ~spec ~n x =
    if n = 0 then
      []
    else
      x :: shift_register ~enable ~spec ~n:(n - 1) (reg spec ~enable x)
  ;;

  let create ~clock ~trigger (rx_data_raw : Signal.t) =
    let spec = Reg_spec.create ~clock () in
    let ctr = wire 3 in
    let last_cycle = (ctr ==:. 7) in
    let busy =
      Signal.reg_fb spec ~enable:vdd ~w:1 (fun busy ->
          mux2 trigger
            (mux2 (busy ==:. 0)
               (mux2 (rx_data_raw ==: vdd)
                  gnd
                  vdd)
               (mux2 last_cycle
                  gnd
                  vdd))
            busy)
    in
    ctr <== (
      Signal.reg_fb spec ~enable:vdd ~w:3 (fun fb ->
          mux2 (busy ==:. 0)
            (zero 3)
            (fb +:. 1)));
    { With_valid.
      valid = last_cycle &: busy
    ; value = Signal.concat_msb (shift_register ~enable:vdd ~n:8 ~spec rx_data_raw)
    }
  ;;
end


type t =
  { mutable tx_data_user : Signal.t Byte_with_valid.t option
  ; mutable rx_data_user : Signal.t Byte_with_valid.t option
  }


let create () =
  { tx_data_user = None; rx_data_user = None }
;;

let set_tx_data_user t tx_data_user =
  match t.tx_data_user with
  | None -> t.tx_data_user <- Some tx_data_user 
  | Some _ -> raise_s [%message "Cannot call set_tx_data_user multiple times"]
;;

let get_rx_data_user t =
  match t.rx_data_user with
  | None ->
    let ret = (Byte_with_valid.Of_signal.wires ()) in
    t.rx_data_user <- Some ret;
    ret
  | Some rx_data_user -> rx_data_user
;;

let trigger ~clock ~when_counter_is =
  let spec = Reg_spec.create ~clock () in
  let width = Signal.width when_counter_is in
  let ctr_next = wire width in
  let ctr = reg ~enable:vdd spec ctr_next in
  ctr_next <== (
    mux2 (ctr ==: when_counter_is)
      (zero width)
      (ctr +:. 1));
  reg ~enable:vdd spec (ctr_next ==: when_counter_is)
;;

let trigger_of_baud_rate ~baud_rate ~clock_in_mhz ~clock =
  (* Approximately, we want to trigger [bit_rate] times every cycle.
   * Something somethign floating point??
   * *)
  let trigger_every_n_cycles = (clock_in_mhz * 1_000_000) / baud_rate in
  let width = Int.ceil_log2 trigger_every_n_cycles in
  trigger
    ~clock
    ~when_counter_is:(of_int ~width (trigger_every_n_cycles - 1))
;;

let complete t ~clock ~rx_data_raw =
  let trigger =
    trigger_of_baud_rate
      ~baud_rate:115_200
      ~clock_in_mhz:100
      ~clock
  in

  begin match t.rx_data_user with
    | None -> ()
    | Some dest ->
      let src = Rx_state_machine.create ~trigger ~clock rx_data_raw in
      dest.valid <== src.valid;
      dest.value <== src.value;
  end;
  begin match t.tx_data_user with
    | None ->
      `Tx_data_raw Signal.vdd
    | Some tx_data_user ->
      `Tx_data_raw (Tx_state_machine.create ~trigger ~clock tx_data_user)
  end;
;;

module Expert = struct
  let create_tx_state_machine = Tx_state_machine.create
  let create_rx_state_machine = Rx_state_machine.create
end

