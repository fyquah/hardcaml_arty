module I = struct
  type 'a t =
    { sys_clk : 'a
    ; ref_clk : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t =
    { led_4bits : 'a [@bits 4]
    }
  [@@deriving sexp_of, hardcaml]
end

