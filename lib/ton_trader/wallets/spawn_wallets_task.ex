defmodule TonTrader.Wallets.SpawnWalletsTask do
  use Task

  alias TonTrader.Wallets

  def start_link(wallet_credentials) do
    Task.start_link(__MODULE__, :run, wallet_credentials)
  end

  def run(wallet_credentials) do
    for creds <- wallet_credentials do
      Wallets.start_wallet_server(wallet_credentials: creds)
    end
  end
end
