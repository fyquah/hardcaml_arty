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

type counter =
  { counter : Signal.t option
  ; last_cycle_trigger : Signal.t
  ; halfway_trigger : Signal.t
  }

let trigger_of_cycles ~clock ~clear ~cycles_per_trigger ~active =
  assert (cycles_per_trigger > 2);
  let spec = Reg_spec.create ~clock ~clear () in
  let cycle_cnt = wire (Int.ceil_log2 cycles_per_trigger) in
  let max_cycle_cnt = (cycles_per_trigger - 1) in
  let next =
    mux2 (~:active |: (cycle_cnt ==:. max_cycle_cnt))
      (zero (width cycle_cnt))
      (cycle_cnt +:. 1)
  in
  cycle_cnt <== reg spec ~enable:vdd next;
  { counter = Some cycle_cnt
  ; last_cycle_trigger =
      active &: (cycle_cnt ==:. max_cycle_cnt)
  ; halfway_trigger =
      active &: (cycle_cnt ==:. (cycles_per_trigger / 2))
  }
;;

module Tx_state_machine = struct
  module States = struct
    type t =
      | S_idle
      | S_start_bit
      | S_data_bits
      | S_stop_bit
    [@@deriving sexp_of, compare, enumerate]
  end

  let create ~clock ~clear ~cycles_per_bit (byte_with_valid : Signal.t Byte_with_valid.t) =
    let spec = Reg_spec.create ~clock ~clear () in
    let sm = Always.State_machine.create (module States) spec ~enable:vdd in
    let increment_cycle_counter = Always.Variable.reg spec ~enable:vdd ~width:1 in
    let { counter = _; last_cycle_trigger = trigger; halfway_trigger = _ } =
      trigger_of_cycles
        ~cycles_per_trigger:cycles_per_bit
        ~clock ~clear ~active:increment_cycle_counter.value
    in
    let byte_cnt = Always.Variable.reg spec ~enable:vdd ~width:3 in
    let output = Always.Variable.wire ~default:vdd in
    let data_latched =
      reg spec ~enable:(sm.is S_idle &: byte_with_valid.valid)
        byte_with_valid.value
      |> Signal.bits_lsb
    in
    ignore (sm.current -- "tx_state" : Signal.t);
    ignore (byte_cnt.value -- "tx_byte_cnt" : Signal.t);
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
              byte_cnt <--. 0;
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
  module States = struct
    type t =
      | S_idle
      | S_start_bit
      | S_data_bits
      (* | S_wait_for_stop_bit *)
      | S_stop_bit
    [@@deriving sexp_of, compare, enumerate]
  end

  let rec shift_register ~enable ~spec ~n x =
    if n = 0 then
      []
    else
      let d = (reg spec ~enable x) in
      d :: shift_register ~enable ~spec ~n:(n - 1) d
  ;;

  let create ~clock ~clear ~cycles_per_bit (rx_data_raw : Signal.t) =
    let spec = Reg_spec.create ~clock ~clear () in
    let sm = Always.State_machine.create (module States) spec ~enable:vdd in
    let increment_cycle_counter = Always.Variable.reg spec ~enable:vdd ~width:1 in
    let cycles_elapsed_for_bit =
      trigger_of_cycles
        ~cycles_per_trigger:cycles_per_bit 
        ~clock ~clear ~active:increment_cycle_counter.value
    in
    let byte_cnt = Always.Variable.reg spec ~enable:vdd ~width:3 in
    let consume_data_bit = Always.Variable.wire ~default:gnd in
    let valid = Always.Variable.wire ~default:gnd in
    ignore (sm.current -- "rx_state" : Signal.t);
    ignore (byte_cnt.value -- "rx_byte_cnt" : Signal.t); 
    Always.(compile [
        sm.switch [
          S_idle, [
            byte_cnt <--. 0;
            when_ (rx_data_raw ==:. 0) [
              increment_cycle_counter <-- vdd;
              sm.set_next S_start_bit;
            ]
          ];
          S_start_bit, [
            if_ cycles_elapsed_for_bit.halfway_trigger [
              when_ (rx_data_raw ==:. 1) [
                increment_cycle_counter <-- gnd;
                sm.set_next S_idle;
              ]
            ] @@ elif cycles_elapsed_for_bit.last_cycle_trigger [
              sm.set_next S_data_bits
            ] @@ [
            ]
          ];
          S_data_bits, [
            consume_data_bit <-- cycles_elapsed_for_bit.halfway_trigger;
            when_ cycles_elapsed_for_bit.last_cycle_trigger [ 
              byte_cnt <-- byte_cnt.value +:. 1;

              when_ (byte_cnt.value ==:. 7) [
                sm.set_next S_stop_bit;
              ]
            ];
          ];
          (*
          S_wait_for_stop_bit, [
            if_ rx_data_raw [
              sm.set_next S_stop_bit;
            ] @@ elif cycles_elapsed_for_bit.last_cycle_trigger [
              (* Overrun, drop frame. *)
              increment_cycle_counter <-- gnd; 
              sm.set_next S_idle;
            ] @@ [
            ]
          ];
             *)
          S_stop_bit, [
            when_ cycles_elapsed_for_bit.last_cycle_trigger [
              valid <--. 1;
              increment_cycle_counter <-- gnd; 
              sm.set_next S_idle;
            ]
          ]
        ]]);
    { With_valid.
      valid = valid.value
    ; value =
        Signal.concat_msb
          (shift_register ~enable:consume_data_bit.value ~spec ~n:8
             rx_data_raw)
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
    t.rx_data_user <- Some ret; ret
  | Some rx_data_user -> rx_data_user
;;

let complete t ~clock ~clear ~rx_data_raw =
  begin match t.rx_data_user with
    | None -> ()
    | Some dest ->
      let src =
        Rx_state_machine.create
          ~cycles_per_bit:((166_667_000 / 115_200)) ~clock ~clear
          rx_data_raw
      in
      dest.valid <== src.valid;
      dest.value <== src.value;
  end;
  begin match t.tx_data_user with
    | None ->
      `Tx_data_raw Signal.vdd
    | Some tx_data_user ->
      `Tx_data_raw (Tx_state_machine.create
                      ~cycles_per_bit:((166_667_000 / 115_200))
                      ~clock
                      ~clear
                      tx_data_user)
  end;
;;

module Expert = struct
  let create_tx_state_machine = Tx_state_machine.create
  let create_rx_state_machine = Rx_state_machine.create
end

