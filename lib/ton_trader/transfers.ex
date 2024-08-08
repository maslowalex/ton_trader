defmodule TonTrader.Transfers do
  @moduledoc """
  Transfering funds between wallets.
  """

  alias TonTrader.Transfers.Requests

  def transfer(from_wallet, to_address, amount, opts \\ []) do
    params = build_transfer_params(from_wallet, to_address, amount, opts)

    Ton.create_transfer_boc(from_wallet.wallet, params)
    |> Base.encode64()
    |> Requests.send_boc()
    |> Finch.request(TonTrader.Finch)
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, status, Jason.decode!(body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def build_transfer_params(from_wallet, to_address, amount, opts \\ []) do
    {:ok, to_address} = Ton.parse_address(to_address)
    timeout = Keyword.get(opts, :timeout, 60)
    comment = Keyword.get(opts, :comment, "")

    [
      seqno: from_wallet.seqno,
      bounce: true,
      secret_key: from_wallet.keypair.secret_key,
      to_address: to_address,
      value: amount,
      timeout: timeout,
      comment: comment
    ]
  end
end
