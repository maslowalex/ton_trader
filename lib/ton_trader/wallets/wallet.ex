defmodule TonTrader.Wallets.Wallet do
  @enforce_keys [:wallet, :mnemonic, :raw_address, :keypair, :pretty_address]
  defstruct @enforce_keys
end
