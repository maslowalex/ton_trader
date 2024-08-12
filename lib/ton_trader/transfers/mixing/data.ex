defmodule TonTrader.Transfers.Mixing.Data do
  @enforce_keys [:origin_wallet, :destination_wallet]
  defstruct [:origin_wallet, :destination_wallet, :intermediaries, strategy: :naive]

  alias TonTrader.Transfers.Mixing.Data

  alias TonTrader.Wallets.Wallet

  def from_opts(opts) do
    with {:ok, origin_wallet} <- opts |> Keyword.fetch!(:wallet) |> ensure_positive_balance(),
         {:ok, intermediaries} <-
           opts |> Keyword.fetch!(:intermediaries) |> validate_intermediaries() do
      destination_wallet = Keyword.fetch!(opts, :destination_wallet)

      %Data{
        origin_wallet: origin_wallet,
        destination_wallet: destination_wallet,
        intermediaries: intermediaries
      }
    end
  end

  defp ensure_positive_balance(%Wallet{balance: nil}) do
    {:error, "Wallet balance must be known"}
  end

  defp ensure_positive_balance(%Wallet{balance: balance} = wallet) do
    if balance > 10 do
      {:ok, wallet}
    else
      {:error, "Wallet balance must be positive"}
    end
  end

  defp validate_intermediaries([%Wallet{} | _] = intermediaries) do
    {:ok, intermediaries}
  end

  defp validate_intermediaries(_) do
    {:error, "Intermediaries must be a list of wallets"}
  end
end
