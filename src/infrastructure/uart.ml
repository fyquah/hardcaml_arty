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
  module States = struct
    type t =
      | S_idle
      | S_start_bit
      | S_data_bits
      | S_stop_bit
    [@@deriving sexp_of, compare, enumerate]
  end

  let create ~clock ~cycles_per_bit (byte_with_valid : Signal.t Byte_with_valid.t) =
    let spec = Reg_spec.create ~clock () in
    let sm = Always.State_machine.create (module States) spec ~enable:vdd in
    let increment_cycle_counter = Always.Variable.reg spec ~enable:vdd ~width:1 in
    let trigger =
      assert (cycles_per_bit > 0);
      if cycles_per_bit = 1 then
        increment_cycle_counter.value
      else
        let cycle_cnt = wire (Int.ceil_log2 cycles_per_bit) in
        let max_cycle_cnt = (cycles_per_bit - 1) in
        let next =
          mux2 (cycle_cnt ==:. max_cycle_cnt)
            (zero (width cycle_cnt))
            (cycle_cnt +:. 1)
        in
        cycle_cnt <== reg spec ~enable:increment_cycle_counter.value next;
        reg spec ~enable:vdd (increment_cycle_counter.value &: (next ==:. max_cycle_cnt))
    in
    let byte_cnt = Always.Variable.reg spec ~enable:vdd ~width:3 in
    let output = Always.Variable.wire ~default:vdd in
    let data_latched =
      reg spec ~enable:(sm.is S_idle &: byte_with_valid.valid)
        byte_with_valid.value
      |> Signal.bits_lsb
    in
    Always.(compile [
        sm.switch [
          S_idle, [
            when_ byte_with_valid.valid [
              increment_cycle_counter <--. 1;
              sm.set_next S_start_bit;
            ]
          ];
          S_start_bit, [
            output <--. 0;
            when_ trigger [
              (* byte_cnt <--. 0 impliciy here *)
              sm.set_next S_data_bits;
            ];
          ];
          S_data_bits, [
            output <-- mux byte_cnt.value data_latched;
            when_ trigger [
              byte_cnt <-- (byte_cnt.value +:. 1);
              when_ (byte_cnt.value ==:. 7) [
                sm.set_next S_stop_bit;
              ]
            ];
          ];
          S_stop_bit, [
            output <--. 1;
            when_ trigger [
              increment_cycle_counter <--. 0;
              sm.set_next S_idle;
            ]
          ]
        ]
      ]);
    output.value
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

let trigger_of_baud_rate ~baud_rate ~clock_in_mhz ~clock =
  (* Approximately, we want to trigger [bit_rate] times every cycle.
   * Something somethign floating point??
   * *)
  let trigger_every_n_cycles = (clock_in_mhz * 1_000_000) / baud_rate in
  let width = Int.ceil_log2 trigger_every_n_cycles in
  Utilities.trigger
    ~clock
    ~when_counter_is:(of_int ~width (trigger_every_n_cycles - 1))
;;

let complete t ~clock ~rx_data_raw =
  let trigger =
    trigger_of_baud_rate
      ~baud_rate:115_200
      ~clock_in_mhz:167
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
      `Tx_data_raw (Tx_state_machine.create
                      ~cycles_per_bit:(166_666_667 / 115_200)
                      ~clock tx_data_user)
  end;
;;

module Expert = struct
  let create_tx_state_machine = Tx_state_machine.create
  let create_rx_state_machine = Rx_state_machine.create
end

