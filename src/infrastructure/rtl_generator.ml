open Hardcaml

type create_fn = Scope.t -> Signal.t User_application.I.t -> Signal.t User_application.O.t

module Top = struct
  module I = struct
    type 'a t =
      { reset : 'a
      ; sys_clock : 'a
      ; usb_uart_rx : 'a
      }
    [@@deriving sexp_of, hardcaml]
  end

  module O = struct
    type 'a t =
      { led_4bits : 'a [@bits 4]
      ; usb_uart_tx : 'a
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
    let uart_state_machine = Uart.create () in
    let sys_clk = clocking_wizard.clk_out1 in
    let user_application =
      User_application.hierarchical
        create_fn
        scope
        { sys_clk
        ; ref_clk = clocking_wizard.clk_out2
        ; uart_rx = Uart.get_rx_data_user uart_state_machine
        }
    in
    Uart.set_tx_data_user uart_state_machine user_application.uart_tx;
    let `Tx_data_raw uart_tx =
      Uart.complete uart_state_machine
        ~clock:sys_clk
        ~rx_data_raw:input.usb_uart_rx
    in
    { O.
      led_4bits = user_application.led_4bits
    ; usb_uart_tx = uart_tx
    }
  ;;
end

let generate (create_fn : create_fn) (output_mode : Rtl.Output_mode.t) =
  let module C = Circuit.With_interface(Top.I)(Top.O) in
  let scope = Scope.create () in
  let circuit = C.create_exn ~name:"hardcaml_arty_top" (Top.create create_fn scope) in
  let database = Scope.circuit_database scope in
  Rtl.output ~database ~output_mode Rtl.Language.Verilog circuit
;;
