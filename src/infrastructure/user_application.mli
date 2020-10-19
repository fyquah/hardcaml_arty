module I : sig
  type 'a t =
    { sys_clk : 'a
    ; ref_clk : 'a
    ; uart_rx : 'a Uart.Byte_with_valid.t
    }
  [@@deriving sexp_of, hardcaml]
end

module O : sig
  type 'a t =
    { led_4bits : 'a
    ; uart_tx : 'a Uart.Byte_with_valid.t
    }
  [@@deriving sexp_of, hardcaml]
end
