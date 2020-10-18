open Hardcaml

module I : sig
  type 'a t =
    { clk_in1 : 'a
    ; resetn : 'a
    } 
  [@@deriving sexp_of, hardcaml]
end

module O : sig
  type 'a t =
    { locked : 'a
    ; clk_out1 : 'a
    ; clk_out2 : 'a
    ; clk_out3 : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

val create : Signal.t I.t -> Signal.t O.t
