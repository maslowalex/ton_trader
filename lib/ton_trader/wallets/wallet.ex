defmodule TonTrader.Wallets.Wallet do
  @enforce_keys [:wallet, :mnemonic, :raw_address, :keypair, :pretty_address, :seqno]
  defstruct @enforce_keys ++ [:balance]
end
