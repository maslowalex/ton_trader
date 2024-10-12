defmodule TonTrader.TonlibRs do
  use Rustler,
    otp_app: :ton_trader,
    crate: :tonlibrs

  def get_wallet_address(_contract_address, _owner_addresses),
    do: :erlang.nif_error(:nif_not_loaded)
end
