defmodule TonTrader.Wallets.Requests do
  alias TonTrader.Wallets

  def get_seqno(pretty_address) when is_binary(pretty_address) do
    Finch.build(
      :post,
      "https://toncenter.com/api/v2/runGetMethod",
      [{"Content-Type", "application/json"}, {"accept", "application/json"}],
      Jason.encode!(%{address: pretty_address, method: "seqno", stack: []})
    )
  end

  def parse_seqno_result(%{"result" => %{"stack" => [["num", "0x" <> seqno]]}}) do
    {:ok, String.to_integer(seqno, 16)}
  end

  def parse_seqno_result(payload) do
    {:error, :invalid_response, payload}
  end
end
