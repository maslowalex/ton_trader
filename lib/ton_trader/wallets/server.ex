defmodule TonTrader.Wallets.Server do
  use GenServer

  require Logger

  alias TonTrader.Wallets
  alias TonTrader.Transfers
  alias TonTrader.Wallets.Wallet
  alias TonTrader.Wallets.Registry

  defmodule State do
    defstruct [:wallet, :last_update_at, :jetton_wallets]
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

      {:noreply,
       %State{
         wallet: wallet,
         last_update_at: NaiveDateTime.utc_now(),
         jetton_wallets: wallet_credentials.jetton_wallets
       }, {:continue, :sync_jetton_balances}}
    else
      error ->
        {:stop, {:shutdown, error}, wallet_credentials}
    end
  end

  def handle_continue(:sync_jetton_balances, state) do
    jetton_wallets =
      Enum.map(state.jetton_wallets, fn jetton_wallet ->
        case Transfers.sync_balance(jetton_wallet.address) do
          {:ok, balance} ->
            {:ok, jetton_wallet} =
              Wallets.update_jetton_wallet(jetton_wallet, %{balance: balance})

            jetton_wallet

          error ->
            Logger.error("Failed to sync jetton wallet balance: #{inspect(error)}")

            jetton_wallet
        end
      end)

    {:noreply, %{state | jetton_wallets: jetton_wallets}}
  end
end
