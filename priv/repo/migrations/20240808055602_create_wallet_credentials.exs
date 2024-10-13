defmodule TonTrader.Repo.Migrations.CreateWalletCredentials do
  use Ecto.Migration

  def change do
    create table(:wallet_credentials, primary_key: false) do
      add :address, :text, primary_key: true
      add :pretty_address, :text, null: false
      add :mnemonic, :text, null: false
      add :seqno, :integer, default: 0, null: false
      add :balance, :decimal, default: 0, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
