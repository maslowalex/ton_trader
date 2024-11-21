defmodule TonTraderWeb.Live.Wallets do
  use TonTraderWeb, :live_view

  alias TonTrader.Wallets
  alias TonTrader.Wallets.Wallet

  def mount(_params, _session, socket) do
    if connected?(socket) do
      for wallet_credential <- Wallets.all_credentials() do
        do_restore_wallet(wallet_credential)
      end
    end

    {:ok, assign(socket, wallets: [], new_wallet_form: to_form(%{}))}
  end

  def render(assigns) do
    ~H"""
    <.button phx-click={show_modal("create-wallet-modal")}>Import Wallet</.button>

    <.table id="wallets" rows={@wallets}>
      <:col :let={wallet} label="Address"><%= wallet.pretty_address %></:col>
      <:col :let={wallet} label="Balance"><%= ton_balance(wallet.balance) %> TON</:col>
    </.table>

    <.modal id="create-wallet-modal">
      <.simple_form phx-submit="create_wallet" for={@new_wallet_form} phx-submit="restore_wallet">
        <.input field={@new_wallet_form[:seed_phrase]} />
        <p>Enter a seed phrase</p>
        <.button type="submit" phx-click={hide_modal("create-wallet-modal")}>Import</.button>
      </.simple_form>
    </.modal>
    """
  end

  def handle_event("restore_wallet", %{"seed_phrase" => seed_phrase}, socket) do
    with {:ok, %{wallet: wallet}} <- Wallets.import_from_mnemonic(seed_phrase),
         %Wallet{} = wallet <- Wallets.prepare_for_transfer(wallet) do
      {:noreply,
       assign(socket, wallets: [wallet | socket.assigns.wallets], new_wallet_form: to_form(%{}))}
    else
      error ->
        {:noreply, put_flash(socket, :error, "Failed to create wallet: #{inspect(error)}")}
    end
  end

  def handle_info({_, {:ok, %Wallet{} = wallet}}, socket) do
    wallets = [wallet | socket.assigns.wallets]

    {:noreply, assign(socket, wallets: Enum.sort_by(wallets, & &1.balance, :desc))}
  end

  def handle_info({:DOWN, _, _, _, _}, socket) do
    {:noreply, socket}
  end

  defp do_restore_wallet(wallet_credential) do
    Task.Supervisor.async_nolink(TonTrader.TaskSupervisor, fn ->
      with {:ok, wallet} <- Wallets.restore_wallet(wallet_credential),
           %Wallet{} = wallet <- Wallets.prepare_for_transfer(wallet) do
        {:ok, wallet}
      end
    end)
  end
end
