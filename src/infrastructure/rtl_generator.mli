open Base
open Hardcaml

val generate
  : (Scope.t -> Signal.t User_application.I.t -> Signal.t User_application.O.t)
  -> Rtl.Output_mode.t
  -> unit
