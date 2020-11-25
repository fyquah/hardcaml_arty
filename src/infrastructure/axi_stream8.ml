module Source = struct
  type 'a t =
    { tdata : 'a [@bits 8]
    ; tlast : 'a
    ; tuser : 'a [@bits 1]
    ; tvalid : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

module Dest = struct
  type 'a t =
    { tready : 'a [@bits 1] }
  [@@deriving sexp_of, hardcaml]
end


