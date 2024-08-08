defmodule TonTrader.WalletsTest do
  use TonTrader.DataCase

  describe "create_wallet/0" do
    test "creates a new wallet and inserts the details of accessing it into the database" do
      assert {:ok, %{wallet: wallet, credentials: credentials}} =
               TonTrader.Wallets.create_wallet()

      assert wallet.raw_address == credentials.address
      assert wallet.pretty_address == credentials.pretty_address
      assert wallet.mnemonic == credentials.mnemonic
    end
  end

  describe "restore_wallet/1" do
    test "restores the wallet, validates the address of the resulting wallet and returns it" do
      {:ok, %{wallet: wallet, credentials: credentials}} = TonTrader.Wallets.create_wallet()

      assert {:ok, ^wallet} = TonTrader.Wallets.restore_wallet(credentials)
    end
  end
end
