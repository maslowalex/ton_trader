defmodule TonTrader.TonlibRs do
  use Rustler,
    otp_app: :ton_trader,
    crate: :tonlibrs

  def get_wallet_address(contract_address, owner_address), do: :erlang.nif_error(:nif_not_loaded)
  def init_client(), do: :erlang.nif_error(:nif_not_loaded)
end
