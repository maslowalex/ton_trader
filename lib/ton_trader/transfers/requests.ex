defmodule TonTrader.Transfers.Requests do
  @moduledoc false

  def send_boc(boc) when is_binary(boc) do
    Finch.build(
      :post,
      "https://toncenter.com/api/v2/sendBoc",
      [{"Content-Type", "application/json"}, {"accept", "application/json"}],
      Jason.encode!(%{boc: boc})
    )
  end

  def get_balance(pretty_address) when is_binary(pretty_address) do
    Finch.build(
      :get,
      "https://toncenter.com/api/v2/getAddressBalance?address=#{pretty_address}",
      [{"accept", "application/json"}]
    )
  end

  def get_jetton_wallet_balances(jetton_master_address, ton_addresses)
      when is_list(ton_addresses) do
    query =
      Enum.reduce(ton_addresses, "?jetton_address=#{jetton_master_address}", fn address, acc ->
        acc <> "&owner_address=#{address}"
      end)

    Finch.build(
      :get,
      "https://toncenter.com/api/v3/jetton/wallets" <> query,
      [{"accept", "application/json"}]
    )
  end
end
