defmodule TonTrader.Wallets.Registry do
  @moduledoc false

  def via(pretty_address) do
    {:via, Registry, {TonTrader.WalletsRegistry, {:wallet, pretty_address}}}
  end

  def put_meta(pretty_address, meta) do
    Registry.put_meta(TonTrader.WalletsRegistry, {:wallet, pretty_address}, meta)
  end

  def get_meta(pretty_address) do
    Registry.meta(TonTrader.WalletsRegistry, {:wallet, pretty_address})
  end

  def all_walets do
    Registry.select(TonTrader.WalletsRegistry, [{{{:wallet, :"$1"}, :_, :_}, [], [:"$1"]}])
  end

  def lookup_wallet(pretty_address) do
    case Registry.lookup(TonTrader.WalletsRegistry, {:wallet, pretty_address}) do
      [{pid, meta}] ->
        {:ok, pid, meta}

      [] ->
        {:error, :not_found}
    end
  end
end
