module I : sig
  type 'a t =
    { sys_clk : 'a
    ; ref_clk : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

module O : sig
  type 'a t =
    { led_4bits : 'a
    }
  [@@deriving sexp_of, hardcaml]
end
