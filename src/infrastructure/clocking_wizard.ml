open Hardcaml

module I = struct
  type 'a t =
    { clk_in1 : 'a
    ; resetn : 'a
    } 
  [@@deriving sexp_of, hardcaml]
end

module O = struct
  type 'a t =
    { locked : 'a
    ; clk_out1 : 'a
    ; clk_out2 : 'a
    ; clk_out3 : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

let create (input : _ I.t) =
  let module Inst = Instantiation.With_interface(I)(O) in
  Inst.create ~name:"design_1_clk_wiz_0_0" input
;;
