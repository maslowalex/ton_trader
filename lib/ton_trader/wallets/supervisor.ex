defmodule TonTrader.Wallets.Supervisor do
  use Supervisor

  alias TonTrader.Wallets.SpawnWalletsTask

  alias TonTrader.Wallets

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    wallet_credentials = Wallets.all_credentials()

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: TonTrader.WalletsDynamicSupervisor},
      {Registry, keys: :unique, name: TonTrader.WalletsRegistry},
      {SpawnWalletsTask, [wallet_credentials]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
