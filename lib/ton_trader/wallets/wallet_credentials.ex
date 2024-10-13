defmodule TonTrader.Wallets.WalletCredentials do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:address, :string, autogenerate: false}
  schema "wallet_credentials" do
    field :pretty_address, :string
    field :mnemonic, :string
    field :seqno, :integer, default: 0
    field :balance, :decimal, default: 0

    has_many :jetton_wallets, TonTrader.Wallets.JettonWallet, foreign_key: :wallet_address

    timestamps(type: :utc_datetime)
  end

  def new(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  @doc false
  def changeset(wallet_credentials, attrs) do
    wallet_credentials
    |> cast(attrs, [:pretty_address, :mnemonic, :address, :seqno, :balance])
    |> validate_mnemonic()
    |> validate_required([:pretty_address, :mnemonic, :address, :seqno])
  end

  def validate_mnemonic(changeset) do
    case get_field(changeset, :mnemonic) do
      nil ->
        changeset

      mnemonic ->
        case String.split(mnemonic, " ") do
          words when length(words) == 24 -> changeset
          _ -> add_error(changeset, :mnemonic, "must be a 24-word mnemonic")
        end
    end
  end
end
