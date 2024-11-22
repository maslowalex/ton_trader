defmodule TonTraderWeb.Live.JettonMasters.Wallets do
  use TonTraderWeb, :live_view

  alias TonTrader.Wallets

  def mount(%{"jetton" => jetton}, _session, socket) do
    socket =
      socket
      |> assign_new(:wallets, fn -> Wallets.get_wallets_for_master(jetton) end)
      |> assign(:jetton, jetton)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.table id="wallets" rows={@wallets}>
      <:col :let={wallet} label="Address"><%= wallet.address %></:col>
      <:col :let={wallet} label="Balance"><%= ton_balance(wallet.balance) %> <%= @jetton %></:col>
    </.table>
    """
  end
end
