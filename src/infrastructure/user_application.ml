module I = struct
  type 'a t =
    { sys_clk : 'a
    ; ref_clk : 'a
    ; uart_rx : 'a Uart.Byte_with_valid.t [@rtlprefix "uart_rx_"]
    }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t =
    { led_4bits : 'a [@bits 4]
    ; uart_tx : 'a Uart.Byte_with_valid.t [@rtlprefix "uart_tx_"]
    }
  [@@deriving sexp_of, hardcaml]
end

