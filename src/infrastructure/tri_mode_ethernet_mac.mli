(* A nice wrapper around the vivado mac. *)

open Hardcaml

module I : sig
  type 'a t =
    { s_axis_tx : 'a Axi_stream8.Source.t [@rtlprefix "tx_axis_mac_"]
    ; s_axis_pause_val : 'a [@rtlname "pause_val"]
    ; s_axis_pause_req : 'a [@rtlname "pause_req"]
    ; glbl_rstn   : 'a
    ; rx_axi_rstn : 'a
    ; tx_axi_rstn : 'a
    ; tx_ifg_delay : 'a [@bits 8]
    ; mii  : 'a Mii.I.t
    }
  [@@deriving sexp_of, hardcaml]
end


module O : sig
  type 'a t =
    { tx_mac_aclk : 'a
    ; s_axis_tx : 'a Axi_stream8.Dest.t [@rtlprefix "tx_axis_mac_"]

    ; rx_mac_aclk : 'a
    ; s_axis_rx : 'a Axi_stream8.Source.t [@rtlprefix "rx_axis_mac_"]

    ; rx_reset : 'a
    ; rx_enable_n : 'a [@rtlname "rx_enable"]

    ; tx_reset : 'a
    ; tx_enable : 'a
    ; speedis100 : 'a
    ; speedis10100 : 'a
    ; mac_irq : 'a
    ; mii  : 'a Mii.O.t
    ; mdc : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

val create : Scope.t -> Signal.t I.t -> Signal.t O.t
