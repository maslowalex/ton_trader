defmodule TonTrader.Wallets.WalletCredentials do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wallet_credentials" do
    field :address, :string, primary_key: true
    field :pretty_address, :string
    field :mnemonic, :string
    field :seqno, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def new(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  @doc false
  def changeset(wallet_credentials, attrs) do
    wallet_credentials
    |> cast(attrs, [:pretty_address, :mnemonic, :address, :seqno])
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
