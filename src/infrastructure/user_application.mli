open Hardcaml

module Led_rgb : sig
  type 'a t =
    { r : 'a
    ; g : 'a
    ; b : 'a
    }
  [@@deriving sexp_of, hardcaml]
end


module I : sig
  type 'a t =
    { 
      (** (Exactly) 166.66667MHz clock and its corresponding synchronous clear. *)
      clk_166 : 'a
    ; clear_n_166 : 'a
    ; (** (Exactly) 200.00000Mhz clock and its corresponding synchronous clear. *)
      clk_200 : 'a
    ; clear_n_200 : 'a
    ; uart_rx : 'a Uart.Byte_with_valid.t
    }
  [@@deriving sexp_of, hardcaml]
end

module O : sig
  type 'a t =
    { led_4bits : 'a
    ; led_rgb : 'a Led_rgb.t list
    ; uart_tx : 'a Uart.Byte_with_valid.t
    }
  [@@deriving sexp_of, hardcaml]
end

val hierarchical
  : ?name: string
  -> (Scope.t -> Signal.t I.t -> Signal.t O.t)
  -> Scope.t -> Signal.t I.t -> Signal.t O.t
