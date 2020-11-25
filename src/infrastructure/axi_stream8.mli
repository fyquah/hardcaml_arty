(* TODO(fyq14): Use library generated ones for this. *)

module Source : sig
  type 'a t =
    { tdata  : 'a
    ; tlast  : 'a
    ; tuser  : 'a
    ; tvalid : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

module Dest : sig
  type 'a t =
    { tready : 'a [@bits 1] }
  [@@deriving sexp_of, hardcaml]
end
