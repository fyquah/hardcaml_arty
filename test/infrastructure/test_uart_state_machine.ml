open Base
open Hardcaml
open Hardcaml_arty

module Waveform = Hardcaml_waveterm.Waveform

let clock = Signal.input "clock" 1

let%expect_test "tx_state_machine" =
  let valid = Signal.input "valid" 1 in
  let value = Signal.input "value" 8 in
  let uart_tx =
    Signal.output 
      "uart_tx"
      (Uart.Expert.create_tx_state_machine ~clock ~cycles_per_bit:1 { valid; value })
  in
  let circuit = Circuit.create_exn ~name:"tx_state_machine" [ uart_tx ] in
  let waves, sim = Hardcaml_waveterm.Waveform.create (Cyclesim.create circuit) in
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "valid") := Bits.vdd;
  (Cyclesim.in_port sim "value") := Bits.of_int ~width:8 0b01010111;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "valid") := Bits.gnd;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Waveform.print ~display_width:80 ~wave_width:1 waves;
  [%expect {|
    ┌Signals───────────┐┌Waves─────────────────────────────────────────────────────┐
    │clock             ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─│
    │                  ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ │
    │valid             ││        ┌───┐                                             │
    │                  ││────────┘   └───────────────────────────────────────────  │
    │                  ││────────┬───────────────────────────────────────────────  │
    │value             ││ 00     │57                                               │
    │                  ││────────┴───────────────────────────────────────────────  │
    │uart_tx           ││────────────┐   ┌───────────┐   ┌───┐   ┌───┐   ┌───────  │
    │                  ││            └───┘           └───┘   └───┘   └───┘         │
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

let%expect_test "rx_state_machine" =
  let trigger = Signal.input "trigger" 1 in
  let uart_rx_raw = Signal.input "uart_rx_raw" 1 in
  let uart_rx =
    (Uart.Expert.create_rx_state_machine ~clock ~trigger uart_rx_raw)
  in
  let valid = Signal.output "valid" uart_rx.valid in
  let value = Signal.output "value" uart_rx.value in
  let circuit = Circuit.create_exn ~name:"rx_state_machine" [ valid; value ] in
  let waves, sim = Hardcaml_waveterm.Waveform.create (Cyclesim.create circuit) in
  let valid = Cyclesim.out_port ~clock_edge:Before sim "valid" in
  let value = Cyclesim.out_port ~clock_edge:Before sim "value" in
  (Cyclesim.in_port sim "trigger") := Bits.vdd;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.vdd;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.gnd;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.vdd;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.gnd;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.vdd;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.gnd;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.vdd;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.gnd;
  Cyclesim.cycle sim;
  (Cyclesim.in_port sim "uart_rx_raw") := Bits.vdd;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  let () =
    assert (Bits.is_vdd !valid);
    Stdio.printf "decoded value = %s\n\n" (Bits.to_string !value);
  in
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Cyclesim.cycle sim;
  Waveform.print ~display_width:80 ~wave_width:1 waves;
  [%expect {|
    decoded value = 11010101

    ┌Signals───────────┐┌Waves─────────────────────────────────────────────────────┐
    │clock             ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─│
    │                  ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ │
    │trigger           ││────────────────────────────────────────────────────────  │
    │                  ││                                                          │
    │uart_rx_raw       ││────────┐   ┌───┐   ┌───┐   ┌───┐   ┌───────────────────  │
    │                  ││        └───┘   └───┘   └───┘   └───┘                     │
    │valid             ││                                        ┌───┐             │
    │                  ││────────────────────────────────────────┘   └───────────  │
    │                  ││────┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───  │
    │value             ││ 80 │C0 │60 │B0 │58 │AC │56 │AB │55 │AA │D5 │EA │F5 │FA   │
    │                  ││────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───  │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    │                  ││                                                          │
    └──────────────────┘└──────────────────────────────────────────────────────────┘ |}]
