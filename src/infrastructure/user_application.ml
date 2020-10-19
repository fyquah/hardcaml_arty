open Base
open Hardcaml

module I = struct
  type 'a t =
    { sys_clk : 'a
    ; ref_clk : 'a
    ; uart_rx : 'a Uart.Byte_with_valid.t [@rtlprefix "uart_rx_"]
    }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t =
    { led_4bits : 'a [@bits 4]
    ; uart_tx : 'a Uart.Byte_with_valid.t [@rtlprefix "uart_tx_"]
    }
  [@@deriving sexp_of, hardcaml]
end

(* TODO(fyq14): Use the hierarchical function [port_checks] argument from
 * [Circuit.Port_checks] when the new hardcaml is properly released.
 *)
let check_port_width (name, width) signal =
  if width <> Signal.width signal then (
    raise_s [%message "Signal width mismatch" (name : string) (width : int)]
  );
;;

let hierarchical ?(name = "user_application") create_fn scope input =
  let module Hierarchy = Hierarchy.In_scope(I)(O) in
  I.(iter2 t input ~f:check_port_width);
  let output = Hierarchy.hierarchical ~name ~scope create_fn input in
  O.(iter2 t output ~f:check_port_width);
  output
;;
