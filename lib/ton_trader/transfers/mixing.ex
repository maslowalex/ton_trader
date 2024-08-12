defmodule TonTrader.Transfers.Mixing do
  @moduledoc """
  This module is responsible for managing the mixing.
  """
  use GenServer, restart: :temporary

  require Logger

  alias TonTrader.Transfers
  alias TonTrader.Wallets
  alias TonTrader.Wallets.Wallet
  alias TonTrader.Transfers.Mixing.ExecutionPlan

  def start_link(exec_plan) do
    GenServer.start_link(__MODULE__, exec_plan, name: __MODULE__)
  end

  def init(exec_plan) do
    {:ok, exec_plan, {:continue, :transfer}}
  end

  def handle_continue(:transfer, %ExecutionPlan{transfers: []} = state) do
    Logger.notice(
      "Mixing from #{address(state.origin_wallet)} to #{address(state.destination_wallet)} is completed successfully"
    )

    {:stop, :normal, state}
  end

  def handle_continue(:transfer, %ExecutionPlan{transfers: [transfer | rest]} = exec_plan) do
    case do_transfer(transfer) do
      :ok ->
        {:noreply, %ExecutionPlan{exec_plan | transfers: rest}, {:continue, :transfer}}

      {:retry, :transfer} ->
        {:noreply, exec_plan, {:continue, :transfer}}

      {:retry, :sync_seqno} ->
        {:noreply, exec_plan, {:continue, {:sync_seqno, transfer.from}}}

      error ->
        {:stop, error, exec_plan}
    end
  end

  def handle_continue({:sync_seqno, wallet}, exec_plan) do
    case Wallets.sync_seqno(wallet) do
      {:ok, sync_wallet} ->
        new_transfer = exec_plan.transfers |> hd() |> Map.put(:from, sync_wallet)
        updated_transfers = List.replace_at(exec_plan.transfers, 0, new_transfer)

        {:noreply, %ExecutionPlan{exec_plan | transfers: updated_transfers},
         {:continue, :transfer}}

      error ->
        Logger.error(
          "Failed to sync seqno for #{address(wallet)}: #{inspect(error)}. Retrying..."
        )

        Process.sleep(1000)

        {:noreply, exec_plan, {:continue, {:sync_seqno, wallet}}}
    end
  end

  def do_transfer(%{from: from, to: to, amount: amount}) do
    Logger.notice("Transferring #{amount} from #{address(from)} to #{address(to)}")

    case Transfers.transfer(from, to, amount) do
      {:ok, _} ->
        Logger.notice("Transfer completed successfully")

        :ok

      {:error, _, :invalid_seqno} ->
        Logger.warning("Invalid seqno, syncing the seqno for #{address(from)}")

        {:retry, :sync_seqno}

      {:error, _, :please_wait} ->
        Logger.warning("Failed to unpack account state, retrying in 3 seconds")

        Process.sleep(3000)

        {:retry, :transfer}

      {:error, 429, _} ->
        Logger.warning("Rate limit exceeded, retrying in 1 second")

        Process.sleep(1000)

        {:retry, :transfer}

      {:error, status, error} ->
        Logger.error("Transfer failed with status #{status}: #{inspect(error)}")

        {:error, error}

      error ->
        Logger.error("Transfer failed: #{inspect(error)}")

        error
    end
  end

  defp address(%Wallet{pretty_address: address}) do
    address
  end

  defp address(addr) when is_binary(addr) do
    addr
  end
end
