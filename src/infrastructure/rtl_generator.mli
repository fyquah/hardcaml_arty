open Base
open Hardcaml

val generate
  : instantiate_ethernet_mac: bool
  -> (Scope.t -> Signal.t User_application.I.t -> Signal.t User_application.O.t)
  -> Rtl.Output_mode.t
  -> unit
