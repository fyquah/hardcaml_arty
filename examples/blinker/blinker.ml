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

let create_ring_register ~clock ~clear ~enable initial_values =
  let initial_values = Array.of_list initial_values in
  let the_wires =
    Array.map initial_values ~f:(fun initial_value ->
        wire (width initial_value))
  in
  let len = Array.length the_wires in
  for i = 0 to len - 1 do
    let spec =
      Reg_spec.create ~clock ~clear ()
      |> Reg_spec.override ~clear_to:initial_values.(i)
    in
    the_wires.(i) <== reg spec ~enable the_wires.((i - 1 + len) % len)
  done;
  the_wires
;;

let create_rgb_led ~clock ~clear =
  let enable =
    let width = 14 in
    let when_counter_is = of_int ~width ((1 lsl width) - 1) in
    Utilities.trigger ~clock ~when_counter_is
  in
  let ring = 
    create_ring_register ~clock ~clear ~enable
      (List.init 12 ~f:(fun i -> if i = 0 then vdd else gnd))
  in
  List.init 4 ~f:(fun i ->
      { User_application.Led_rgb.
        r = ring.(3 * i)
      ; g = ring.(3 * i + 1)
      ; b = ring.(3 * i + 2)
      })
;;

let create _scope (input : _ User_application.I.t) =
  let led_4bits = create_led4_bits ~clock:input.clk_166 in
  let led_rgb =
    create_rgb_led
      ~clock:input.clk_166 ~clear:~:(input.clear_n_166)
  in
  let uart_tx =
    { With_valid.valid = input.uart_rx.valid; value = input.uart_rx.value }
  in
  { User_application.O. led_4bits; uart_tx; led_rgb }
;;

let () =
  Hardcaml_arty.Rtl_generator.generate create (To_channel Stdio.stdout)
;;
