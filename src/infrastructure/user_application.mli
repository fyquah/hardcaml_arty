open Hardcaml

module Ethernet : sig
  module I : sig
    type 'a t =
      { clk_rx  : 'a
        (** A 125MHz clock corresponding to the output data stream. *)
      ; rx      : 'a Axi_stream8.Source.t

      ; clk_tx  : 'a
        (** A 125MHz clock corresponding to the TX data stream. *)
      ; tx_dest : 'a Axi_stream8.Dest.t
      }
    [@@deriving sexp_of, hardcaml]
  end

  module O : sig
    type 'a t = { tx : 'a Axi_stream8.Source.t }
    [@@deriving sexp_of, hardcaml]

    val unused : (module Comb.S with type t = 'a) -> 'a t
  end
end

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
    { clk_166 : 'a
      (** (Exactly) 166.66667MHz clock and its corresponding synchronous 
          active low clear. *)
    ; clear_n_166 : 'a
    ; clk_200 : 'a
      (** (Exactly) 200.00000Mhz clock and its corresponding synchronous
          active low clear. *)
    ; clear_n_200 : 'a
    ; uart_rx : 'a Uart.Byte_with_valid.t
    ; ethernet : 'a Ethernet.I.t
    }
  [@@deriving sexp_of, hardcaml]
end

module O : sig
  type 'a t =
    { led_4bits : 'a
    ; led_rgb : 'a Led_rgb.t list
    ; uart_tx : 'a Uart.Byte_with_valid.t
    ; ethernet : 'a Ethernet.O.t
    }
  [@@deriving sexp_of, hardcaml]
end

val hierarchical
  : ?name: string
  -> (Scope.t -> Signal.t I.t -> Signal.t O.t)
  -> Scope.t -> Signal.t I.t -> Signal.t O.t
