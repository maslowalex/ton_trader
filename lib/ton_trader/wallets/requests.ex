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
