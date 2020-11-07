open Base
open Hardcaml
open Hardcaml_arty
open Signal

let of_int_minimum_width n =
  let width = Signal.num_bits_to_represent n in
  Signal.of_int ~width n
;;

let create_led4_bits ~clock =
    let reg_spec = Reg_spec.create ~clock () in
    let ctr =
      reg_fb reg_spec ~enable:vdd ~w:30 (fun fb -> fb +:. 1)
    in
    concat_lsb (List.init 4 ~f:(fun i -> sel_top ctr 2 ==:. i))
;;

let create _scope (input : _ User_application.I.t) =
  let led_4bits = create_led4_bits ~clock:input.clk_166 in
  let led_rgb = List.init 4 ~f:(fun _ ->
      { User_application.Led_rgb.  r = gnd ; g = gnd ; b = gnd })
  in
  let uart_tx =
    { With_valid.valid = input.uart_rx.valid; value = input.uart_rx.value }
  in
  { User_application.O. led_4bits; uart_tx; led_rgb }
;;

let () =
  Hardcaml_arty.Rtl_generator.generate create (To_channel Stdio.stdout)
;;
