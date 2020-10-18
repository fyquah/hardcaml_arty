open Base
open Hardcaml
open Hardcaml_arty
open Signal

let create _scope (input : _ User_application.I.t) =
  let clock = input.ref_clk in
  let reg_spec = Reg_spec.create ~clock () in
  let ctr =
    reg_fb reg_spec ~enable:vdd ~w:30 (fun fb -> fb +:. 1)
  in
  let led_4bits = concat_lsb (List.init 4 ~f:(fun i -> sel_top ctr 2 ==:. i)) in
  { User_application.O.
    led_4bits
  }
;;

let () =
  Hardcaml_arty.Rtl_generator.generate create (To_channel Stdio.stdout)
;;
