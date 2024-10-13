defmodule TonTrader.Wallets.JettonMaster do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "jetton_masters" do
    field :address, :binary, primary_key: true
    field :decimals, :integer, default: 9
    field :name, :string
  end

  @doc false
  def changeset(master_wallet, attrs) do
    master_wallet
    |> cast(attrs, [:address, :name, :decimals])
    |> validate_required([:address, :name, :decimals])
  end
end
