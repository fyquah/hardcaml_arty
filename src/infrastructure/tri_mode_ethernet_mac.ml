open Hardcaml

module I = struct
  type 'a t =
    { s_axis_tx : 'a Axi_stream8.Source.t [@rtlprefix "tx_axis_mac_"]
    ; s_axis_pause_val : 'a [@bits 16] [@rtlname "pause_val"]
    ; s_axis_pause_req : 'a [@rtlname "pause_req"]
    ; glbl_rstn   : 'a
    ; rx_axi_rstn : 'a
    ; tx_axi_rstn : 'a
    ; tx_ifg_delay : 'a [@bits 8]
    ; mii  : 'a Mii.I.t
    }
  [@@deriving sexp_of, hardcaml]
end


module O = struct
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

let create _scope (input : _ I.t) =
  let module Inst = Instantiation.With_interface(I)(O) in
  Inst.create ~name:"hardcaml_arty_tri_mode_ethernet_mac_0" input
;;
