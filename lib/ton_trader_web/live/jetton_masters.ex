defmodule TonTraderWeb.Live.JettonMasters do
  use TonTraderWeb, :live_view

  alias TonTrader.Wallets
  alias TonTrader.Wallets.JettonMaster

  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok,
       assign(socket,
         jetton_masters: TonTrader.Wallets.all_jetton_masters(),
         new_jetton_master: new_jetton_master()
       )}
    else
      {:ok, assign(socket, jetton_masters: [], new_jetton_master: new_jetton_master())}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.button phx-click={show_modal("add-jetton-master-modal")}>Create Jetton Master</.button>

      <.table id="wallets" rows={@jetton_masters}>
        <:col :let={jetton_master} label="Name">
          <.link navigate={~p"/jetton-masters/#{jetton_master.name}/wallets"}>
            <%= jetton_master.name %>
          </.link>
        </:col>
        <:col :let={jetton_master} label="Address"><%= jetton_master.address %></:col>
        <:col :let={jetton_master} label="Decimals"><%= jetton_master.decimals %></:col>
      </.table>

      <.modal id="add-jetton-master-modal">
        <.simple_form phx-submit="create_jetton_master" for={@new_jetton_master}>
          <.input field={@new_jetton_master[:name]} label="Name" />
          <.input field={@new_jetton_master[:address]} label="Address" />
          <.input field={@new_jetton_master[:decimals]} label="Decimals" />
          <.button type="submit" phx-click={hide_modal("create-wallet-modal")}>Create</.button>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  def handle_event("create_jetton_master", %{"jetton_master" => jetton_master_params}, socket) do
    case Wallets.insert_master_wallet(jetton_master_params) do
      {:ok, jetton_master} ->
        do_derive_wallets(jetton_master)

        {:noreply,
         assign(socket,
           new_jetton_master: new_jetton_master(),
           jetton_masters: TonTrader.Wallets.all_jetton_masters()
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, new_jetton_master: changeset)}
    end
  end

  def handle_info(
        {_, {:ok, :wallets_derived_successfully, %{errors: error_count, derived: derived_count}}},
        socket
      ) do
    {:noreply,
     put_flash(
       socket,
       :info,
       "Completed wallets creation. #{derived_count} wallets derived, #{error_count} errors."
     )}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp do_derive_wallets(jetton_master) do
    Task.Supervisor.async_nolink(TonTrader.TaskSupervisor, fn ->
      existing_wallet_pretty_addresses = Wallets.all_ton_wallet_addresses()

      result = Wallets.derive_jetton_wallets(jetton_master, existing_wallet_pretty_addresses)

      errors_count =
        result
        |> Enum.filter(fn
          {:error, _} -> true
          _ -> false
        end)
        |> Enum.count()

      {:ok, :wallets_derived_successfully,
       %{errors: errors_count, derived: length(result) - errors_count}}
    end)
  end

  defp new_jetton_master do
    to_form(JettonMaster.new())
  end
end
