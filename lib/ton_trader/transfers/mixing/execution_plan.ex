defmodule TonTrader.Transfers.Mixing.ExecutionPlan do
  @moduledoc """
  This module is responsible for managing the execution plan of the mixing.
  """
  alias TonTrader.Transfers.Mixing.ExecutionPlan

  defstruct [:transfers, :origin_wallet, :destination_wallet, :estimated_total_gas_fee]

  def from_data(%{strategy: :naive} = data) do
    initial_balance = data.origin_wallet.balance
    per_intermediary_transfer_amount = floor(initial_balance / Enum.count(data.intermediaries))
    estimated_gas_fee = 100

    to_intermediaries_transfer =
      data.intermediaries
      |> Enum.map(fn intermediary ->
        %{
          from: data.origin_wallet,
          to: intermediary.pretty_address,
          amount: per_intermediary_transfer_amount - estimated_gas_fee
        }
      end)

    to_destination_transfer =
      Enum.map(data.intermediaries, fn intermediary ->
        %{
          from: intermediary,
          to: data.destination_wallet,
          amount: per_intermediary_transfer_amount - estimated_gas_fee * 2
        }
      end)

    transfers = to_intermediaries_transfer ++ to_destination_transfer

    %ExecutionPlan{
      transfers: transfers,
      origin_wallet: data.origin_wallet,
      destination_wallet: data.destination_wallet,
      estimated_total_gas_fee: Enum.count(data.intermediaries) * 2 * estimated_gas_fee
    }
  end

  def to_human_readable(%__MODULE__{transfers: transfers}) do
    Enum.map(transfers, fn t -> %{from: t.from.pretty_address, to: t.to, amount: t.amount} end)
  end
end
