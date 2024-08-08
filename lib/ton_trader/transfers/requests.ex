defmodule TonTrader.Transfers.Requests do
  @moduledoc false

  alias TonTrader.Wallets.Wallet

  def send_boc(boc) when is_binary(boc) do
    Finch.build(
      :post,
      "https://toncenter.com/api/v2/sendBoc",
      [{"Content-Type", "application/json"}, {"accept", "application/json"}],
      Jason.encode!(%{boc: boc})
    )
  end
end
