open Hardcaml

type create_fn = Scope.t -> Signal.t User_application.I.t -> Signal.t User_application.O.t

module Top = struct
  module I = struct
    type 'a t =
      { reset : 'a
      ; sys_clock : 'a
      }
    [@@deriving sexp_of, hardcaml]
  end

  module O = struct
    type 'a t =
      { led_4bits : 'a [@bits 4]
      }
    [@@deriving sexp_of, hardcaml]
  end

  let create (create_fn : create_fn) scope (input : _ I.t) =
    let clocking_wizard =
      Clocking_wizard.create 
        { clk_in1 = input.sys_clock
        ; resetn  = input.reset
        }
    in
    let user_application =
      create_fn
        scope
        { sys_clk = clocking_wizard.clk_out1
        ; ref_clk = clocking_wizard.clk_out2
        }
    in
    { O. led_4bits = user_application.led_4bits }
  ;;
end

let generate (create_fn : create_fn) (output_mode : Rtl.Output_mode.t) =
  let module C = Circuit.With_interface(Top.I)(Top.O) in
  let scope = Scope.create () in
  let circuit = C.create_exn ~name:"hardcaml_arty_top" (Top.create create_fn scope) in
  let database = Scope.circuit_database scope in
  Rtl.output ~database ~output_mode Rtl.Language.Verilog circuit
;;
