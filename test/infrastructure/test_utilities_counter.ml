open Base
open Hardcaml
open Hardcaml_arty

module Waveform = Hardcaml_waveterm.Waveform

let clock = Signal.input "clock" 1

let%expect_test "simple counter" =
  let trigger = Signal.input "trigger" 1 in
  let cnt =
    Utilities.counter ~clock ~trigger
      ~minimum:(Char.to_int 'a')
      ~maximum:(Char.to_int 'z')
  in
  let circuit = Circuit.create_exn ~name:"tx_state_machine" [ Signal.output "count" cnt ] in
  let waves, sim = Hardcaml_waveterm.Waveform.create (Cyclesim.create circuit) in
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "trigger") := Bits.vdd;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Waveform.print ~display_width:80 ~wave_width:1 waves;
  [%expect {|
    ┌Signals───────────┐┌Waves─────────────────────────────────────────────────────┐
    │clock             ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─│
    │                  ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ │
    │trigger           ││            ┌───────────                                  │
    │                  ││────────────┘                                             │
    │                  ││────────────────┬───┬───                                  │
    │count             ││ 61             │62 │63                                   │
    │                  ││────────────────┴───┴───                                  │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    └──────────────────┘└──────────────────────────────────────────────────────────┘ |}]
;;
