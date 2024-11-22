defmodule TonTrader.Wallets.Server do
  use GenServer

  alias TonTrader.Wallets
  alias TonTrader.Wallets.Wallet
  alias TonTrader.Wallets.Registry

  defmodule State do
    defstruct [:wallet, :last_update_at]
  end

  def start_link(opts) do
    wallet_credentials = Keyword.fetch!(opts, :wallet_credentials)

    GenServer.start_link(__MODULE__, wallet_credentials,
      name: Registry.via(wallet_credentials.pretty_address)
    )
  end

  def init(wallet_credentials) do
    {:ok, wallet_credentials, {:continue, :do_restore_wallet}}
  end

  def handle_continue(:do_restore_wallet, wallet_credentials) do
    with {:ok, wallet} <- Wallets.restore_wallet(wallet_credentials),
         %Wallet{} = wallet <- Wallets.prepare_for_transfer(wallet) do
      :ok = Registry.put_meta(wallet.pretty_address, Map.take(wallet, [:balance]))

      {:noreply, %State{wallet: wallet, last_update_at: NaiveDateTime.utc_now()}}
    else
      error ->
        {:stop, {:shutdown, error}, wallet_credentials}
    end
  end
end
