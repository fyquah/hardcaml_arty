open Base
open Hardcaml
open Signal

let counter ~clock ~trigger ~minimum ~maximum =
  assert (minimum <= maximum);
  let spec = Reg_spec.create ~clock () in
  let width = Signal.num_bits_to_represent maximum in
  if maximum = minimum then (
    Signal.of_int ~width maximum
  ) else (
    let ctr_next = wire (Int.ceil_log2 (maximum - minimum + 1)) in
    let ctr = reg ~enable:trigger spec ctr_next in
    ctr_next <== (
      mux2 (ctr ==:. (maximum - minimum))
        (zero (Signal.width ctr_next))
        (ctr +:. 1)
    );
    Signal.uresize ctr width +:. minimum
  )
;;

let trigger ~clock ~when_counter_is =
  let spec = Reg_spec.create ~clock () in
  let width = Signal.width when_counter_is in
  let ctr_next = wire width in
  let ctr = reg ~enable:vdd spec ctr_next in
  ctr_next <== (
    mux2 (ctr ==: when_counter_is)
      (zero width)
      (ctr +:. 1));
  reg ~enable:vdd spec (ctr_next ==: when_counter_is)
;;
