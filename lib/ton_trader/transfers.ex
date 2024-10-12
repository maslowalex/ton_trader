defmodule TonTrader.Transfers do
  @moduledoc """
  Transfering funds between wallets.
  """

  alias TonTrader.Transfers.Requests

  def sync_balance(wallet) do
    wallet.pretty_address
    |> Requests.get_balance()
    |> TonTrader.RateLimiter.request()
    |> case do
      {:ok, %{status: 200, body: body}} ->
        balance = body |> Jason.decode!() |> Map.fetch!("result") |> String.to_integer()

        %{wallet | balance: balance}

      {_, reason} ->
        {:error, reason}
    end
  end

  def transfer(from_wallet, to_address, amount, opts \\ []) do
    params = build_transfer_params(from_wallet, to_address, amount, opts)

    Ton.create_transfer_boc(from_wallet.wallet, params)
    |> Base.encode64()
    |> Requests.send_boc()
    |> TonTrader.RateLimiter.request()
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %{status: status, body: body}} ->
        error = body |> Jason.decode!() |> build_transfer_error()

        {:error, status, error}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def build_transfer_params(from_wallet, to_address, amount, opts \\ []) do
    {:ok, to_address} = Ton.parse_address(to_address)
    timeout = Keyword.get(opts, :timeout, 60)
    comment = Keyword.get(opts, :comment, "")
    bounce = Keyword.get(opts, :bounce, true)

    [
      seqno: from_wallet.seqno,
      bounce: bounce,
      secret_key: from_wallet.keypair.secret_key,
      to_address: to_address,
      value: amount,
      timeout: timeout,
      comment: comment
    ]
  end

  def build_transfer_error(%{"error" => error}) do
    cond do
      String.contains?(error, "exitcode=33") ->
        :invalid_seqno

      String.contains?(error, "Failed to unpack account state") ->
        :please_wait

      true ->
        {:unknown_error, error}
    end
  end
end
