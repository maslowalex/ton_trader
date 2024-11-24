defmodule TonTrader.Wallets.UpdateJettonWalletBalances do
  @moduledoc """
  Service module for updating jetton wallet balances in bulk.
  """

  alias TonTrader.Wallets
  alias TonTrader.Wallets.JettonMaster
  alias TonTrader.Wallets.Requests

  def call(%JettonMaster{address: master_address, name: master_name}) do
    jetton_wallets =
      master_name
      |> Wallets.get_wallets_for_master()
      |> Enum.map(& &1.address)

    master_address
    |> Requests.get_jetton_wallet_balances(jetton_wallets)
    |> TonTrader.RateLimiter.request()
  end
end
