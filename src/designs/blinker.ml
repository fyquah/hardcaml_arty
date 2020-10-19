open Base
open Hardcaml
open Hardcaml_arty
open Signal

let of_int_minimum_width n =
  let width = Signal.num_bits_to_represent n in
  Signal.of_int ~width n
;;

let create _scope (input : _ User_application.I.t) =
  let led_4bits =
    let clock = input.ref_clk in
    let reg_spec = Reg_spec.create ~clock () in
    let ctr =
      reg_fb reg_spec ~enable:vdd ~w:30 (fun fb -> fb +:. 1)
    in
    concat_lsb (List.init 4 ~f:(fun i -> sel_top ctr 2 ==:. i))
  in
  let uart_tx =
    let clock = input.sys_clk in
    let valid =
      Utilities.trigger
        ~clock
        ~when_counter_is:(of_int_minimum_width 167_777_777)
    in
    let value =
      Utilities.counter
        ~clock
        ~trigger:valid
        ~minimum:(Char.to_int 'a')
        ~maximum:(Char.to_int 'z')
    in
    { With_valid.valid; value }
  in
  { User_application.O. led_4bits; uart_tx }
;;

let () =
  Hardcaml_arty.Rtl_generator.generate create (To_channel Stdio.stdout)
;;
