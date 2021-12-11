module I : sig
  type 'a t =
    { mii_rx_clk : 'a
    ; mii_rx_dv  : 'a
    ; mii_rx_er  : 'a
    ; mii_rxd    : 'a
    ; mii_tx_clk : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

module O : sig
  type 'a t =
    { mii_tx_en : 'a
    ; mii_txd   : 'a
    }
  [@@deriving sexp_of, hardcaml]
end

