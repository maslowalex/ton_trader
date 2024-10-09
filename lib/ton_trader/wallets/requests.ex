defmodule TonTrader.Wallets.Requests do
  @moduledoc false

  def get_seqno(pretty_address) when is_binary(pretty_address) do
    %{address: pretty_address, method: "seqno", stack: []}
    |> Jason.encode!()
    |> run_get_method()
  end

  def parse_seqno_result(%{"result" => %{"stack" => [["num", "0x" <> seqno]]}}) do
    {:ok, String.to_integer(seqno, 16)}
  end

  def parse_seqno_result(payload) do
    {:error, :invalid_response, payload}
  end

  defp run_get_method(json_payload) do
    Finch.build(
      :post,
      "https://toncenter.com/api/v2/runGetMethod",
      [{"Content-Type", "application/json"}, {"accept", "application/json"}],
      json_payload
    )
  end
end
