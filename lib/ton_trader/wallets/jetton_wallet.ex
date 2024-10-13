defmodule TonTrader.Wallets.JettonWallet do
  use Ecto.Schema
  import Ecto.Changeset

  @foreign_key_type :binary
  @primary_key {:address, :binary, autogenerate: false}
  schema "jetton_wallets" do
    field :balance, :decimal

    belongs_to :jetton_master, TonTrader.Wallets.JettonMaster,
      foreign_key: :jetton_master_address,
      references: :address

    belongs_to :wallet_credentials, TonTrader.Wallets.WalletCredentials,
      foreign_key: :wallet_address,
      references: :address
  end

  @doc false
  def changeset(jetton_wallet, attrs) do
    jetton_wallet
    |> cast(attrs, [:address, :balance])
    |> validate_required([:address, :balance])
  end
end
