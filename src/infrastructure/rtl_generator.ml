open Base
open Hardcaml
open Signal

type create_fn = Scope.t -> Signal.t User_application.I.t -> Signal.t User_application.O.t

module Top = struct
  module I = struct
    type 'a t =
      { reset : 'a
      ; sys_clock : 'a
      ; usb_uart_rx : 'a
      ; push_buttons_4bits : 'a [@bits 4]
      ; eth_mii            : 'a Mii.I.t [@rtlprefix "eth_"]
      }
    [@@deriving sexp_of, hardcaml]
  end

  module O = struct
    type 'a t =
      { led_4bits   : 'a [@bits 4]
      ; led_rgb     : 'a [@bits 12]
      ; usb_uart_tx : 'a
      ; eth_mii     : 'a Mii.O.t  [@rtlprefix "eth_"]
      ; mdc         : 'a
      }
    [@@deriving sexp_of, hardcaml]
  end

  let cdc_trigger ~clock value  =
    let spec = Reg_spec.create ~clock () in
    let enable = Signal.vdd in
    Signal.reg spec ~enable value
    |> Fn.flip Signal.add_attribute (Rtl_attribute.Vivado.async_reg true)
    |> Signal.reg spec ~enable
  ;;

  let create ~instantiate_ethernet_mac (create_fn : create_fn) scope (input : _ I.t) =
    let clocking_wizard =
      Clocking_wizard.create
        { clk_in1 = input.sys_clock
        ; resetn  = input.reset
        }
    in
    let uart_state_machine = Uart.create () in
    let clk_166 = clocking_wizard.clk_out1 in
    let clk_200 = clocking_wizard.clk_out2 in
    let clear_n_166 = cdc_trigger ~clock:clk_166 clocking_wizard.locked in
    let user_application_o = User_application.O.Of_signal.wires () in
    let tri_mode_ethernet_mac =
      if instantiate_ethernet_mac then
        Tri_mode_ethernet_mac.create scope
          { s_axis_tx = user_application_o.ethernet.tx
          ; s_axis_pause_val = Signal.zero 16
          ; s_axis_pause_req = Signal.zero 1
          ; glbl_rstn        = clocking_wizard.locked
          ; rx_axi_rstn      = clocking_wizard.locked
          ; tx_axi_rstn      = clocking_wizard.locked
          ; tx_ifg_delay     = Signal.zero 8
          ; mii              = input.eth_mii
          }
      else
        Tri_mode_ethernet_mac.O.Of_signal.of_int 0
    in
    let user_application =
      User_application.hierarchical
        create_fn
        scope
        { clk_166
        ; clk_200
        ; clear_n_166
        ; clear_n_200 = cdc_trigger ~clock:clk_200 clocking_wizard.locked
        ; uart_rx = Uart.get_rx_data_user uart_state_machine
        ; ethernet =
            { clk_rx  = tri_mode_ethernet_mac.rx_mac_aclk
            ; rx      = tri_mode_ethernet_mac.s_axis_rx
            ; clk_tx  = tri_mode_ethernet_mac.tx_mac_aclk
            ; tx_dest = tri_mode_ethernet_mac.s_axis_tx
            }
        }
    in
    User_application.O.iter2 user_application_o user_application ~f:(<==);
    Uart.set_tx_data_user uart_state_machine user_application.uart_tx;
    let `Tx_data_raw uart_tx =
      Uart.complete uart_state_machine
        ~clock:clk_166
        ~clear:~:(clear_n_166)
        ~rx_data_raw:input.usb_uart_rx
    in
    { O.
      led_4bits = user_application.led_4bits
    ; usb_uart_tx = uart_tx
    ; led_rgb =
        List.concat_map (List.rev user_application.led_rgb) ~f:(fun led ->
            [ led.b; led.g; led.r ])
        |> Signal.concat_msb
    ; eth_mii  = tri_mode_ethernet_mac.mii
    ; mdc = tri_mode_ethernet_mac.mdc
    }
  ;;
end

let generate ~instantiate_ethernet_mac (create_fn : create_fn) (output_mode : Rtl.Output_mode.t) =
  let module C = Circuit.With_interface(Top.I)(Top.O) in
  let scope = Scope.create () in
  let circuit =
    C.create_exn ~name:"hardcaml_arty_top"
      (Top.create ~instantiate_ethernet_mac create_fn scope)
  in
  let database = Scope.circuit_database scope in
  Rtl.output ~database ~output_mode Rtl.Language.Verilog circuit
;;
