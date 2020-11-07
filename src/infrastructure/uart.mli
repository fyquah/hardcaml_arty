open Base
open Hardcaml

module Byte_with_valid : sig
  include Hardcaml.Interface.S with type 'a t = 'a With_valid.t
end

type t

val create : unit -> t

(** Sets the tx data from the UART pins. Should only ever be called once,
    raises an exception when called multiple times.
*)
val set_tx_data_user : t -> Signal.t Byte_with_valid.t -> unit

(** Gets the decoded RX data.  *)
val get_rx_data_user : t -> Signal.t Byte_with_valid.t

val complete
  : t
  -> clock: Signal.t
  -> clear: Signal.t
  -> rx_data_raw : Signal.t
  -> [ `Tx_data_raw of Signal.t ]

module Expert : sig
  val create_tx_state_machine
    :  clock : Signal.t
    -> clear: Signal.t
    -> cycles_per_bit: int
    -> Signal.t Byte_with_valid.t
    -> Signal.t 

  val create_rx_state_machine
    :  clock : Signal.t
    -> clear: Signal.t
    -> cycles_per_bit: int
    -> Signal.t 
    -> Signal.t Byte_with_valid.t
end

