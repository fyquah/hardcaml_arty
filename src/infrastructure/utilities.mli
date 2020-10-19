open Hardcaml
type signal := Signal.t

val counter
  : clock: signal
  -> trigger: signal
  -> minimum: int
  -> maximum: int
  -> signal

val trigger : clock: signal -> when_counter_is: signal -> signal

