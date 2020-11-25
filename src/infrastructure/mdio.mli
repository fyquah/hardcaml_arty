module I : sig
  type 'a t =
    { mdio_i : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

module O : sig
  type 'a t =
    { mdc    : 'a
    ; mdio_o : 'a
    ; mdio_t : 'a
    }
  [@@deriving sexp_of, hardcaml]
end
