defmodule TonTraderWeb.Live.Wallets do
  use TonTraderWeb, :live_view

  alias TonTrader.Wallets
  alias TonTrader.Wallets.Wallet
  alias TonTrader.Wallets.Registry

  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        wallets_short_info =
          for wallet_pretty_address <- Registry.all_walets() do
            with {:ok, %{balance: _} = meta} <- Registry.get_meta(wallet_pretty_address) do
              Map.merge(meta, %{pretty_address: wallet_pretty_address})
            else
              _ ->
                %{pretty_address: wallet_pretty_address, balance: nil}
            end
          end

        assign(socket, :wallets, sort_wallets(wallets_short_info))
      else
        assign(socket, :wallets, [])
      end

    {:ok, assign(socket, new_wallet_form: to_form(%{}))}
  end

  def render(assigns) do
    ~H"""
    <.button phx-click={show_modal("create-wallet-modal")}>Import Wallet</.button>

    <.table id="wallets" rows={@wallets}>
      <:col :let={wallet} label="Address"><%= wallet.pretty_address %></:col>
      <:col :let={wallet} label="Balance"><%= ton_balance(wallet.balance) %> TON</:col>
    </.table>

    <.modal id="create-wallet-modal">
      <.simple_form for={@new_wallet_form} phx-submit="restore_wallet">
        <.input field={@new_wallet_form[:seed_phrase]} />
        <p>Enter a seed phrase</p>
        <.button type="submit" phx-click={hide_modal("create-wallet-modal")}>Import</.button>
      </.simple_form>
    </.modal>
    """
  end

  def handle_event("restore_wallet", %{"seed_phrase" => seed_phrase}, socket) do
    with {:ok, %{wallet: wallet, credentials: creds}} <-
           Wallets.import_from_mnemonic(seed_phrase),
         %Wallet{} = wallet <- Wallets.prepare_for_transfer(wallet) do
      _ = Wallets.start_wallet_server(wallet_credentials: creds)
      updated_wallets = [Map.take(wallet, [:pretty_address, :balance]) | socket.assigns.wallets]

      {:noreply,
       assign(socket,
         wallets: sort_wallets(updated_wallets),
         new_wallet_form: to_form(%{})
       )}
    else
      error ->
        {:noreply, put_flash(socket, :error, "Failed to create wallet: #{inspect(error)}")}
    end
  end

  defp sort_wallets(wallets) do
    Enum.sort_by(wallets, & &1.balance, :desc)
  end
end
