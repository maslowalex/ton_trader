defmodule TonTrader.TonlibRs do
  use Rustler,
    otp_app: :ton_trader,
    crate: :tonlibrs

  @doc """
  Given the TON addresses list and the jetton master contract address,
  returns a mapping from TON address to jetton address.
  """
  def get_wallet_address(_contract_address, _owner_addresses),
    do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Generates a transfer boc for jetton transfer.

  # Example
  iex> transfer = %TonTrader.TonlibRs.JettonTransfer{
    report_wallet_address: "EQDtcAEyDrVPPRcJXjy0b7rgO96rHpLAU1rzWvQbo5pLL9ff",
    destination_jetton_wallet_address: "EQBkwsN4sWHm_stwIihehDvj5giCW4RILFkb7TzUdUPyz7iK",
    sender_jetton_address: "EQB9fnjfz5W3s6DYfclSc5PMfVStk2HvcskRQ1znLdwzDrbD",
    sender_wallet_mnemonic: "hybrid capital topic try scale half syrup slight gospel chicken rude stereo december tragic aware embrace decade siren utility kitten tiny basket eternal practice",
    sender_wallet_seqno: 88,
    jetton_amount: 7500000000000,
    ton_forward_amount: 10000,
    ton_amount: 300000000
  }

  TonTrader.TonlibRs.jetton_transfer_boc(transfer)

  "te6cckECBAEAAQgAAUWIAdrgAmQdap56LhK8eWjfdcB3vVY9JYCmtea16DdHNJZeDAEBnJGntyFu798J8G1Fz0Iq4ES+ChWGeFPYJh7KrTny+qjNJR+xG6QvYEIYt1QI7eNxfKEvdpS9ew7MA6K3t80fFA8pqaMXZwvS8wAAAFgAAwIBaGIAPr88b+fK29nQbD7kqTnJ5j6qVsmw97lkiKGuc5buGYcgjw0YAAAAAAAAAAAAAAAAAAEDALAPin6lAAAAAAAAAABgbSOtX4AIAMmFhvFiw839luBEUL0Id8fMEQS3CJBYsjfaeajqh+WfADtcAEyDrVPPRcJXjy0b7rgO96rHpLAU1rzWvQbo5pLLxE4g2blbSg=="
  """
  def jetton_transfer_boc(_params), do: :erlang.nif_error(:nif_not_loaded)
end
