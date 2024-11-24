defmodule TonTrader.Repo.Migrations.CreateJettonWallets do
  use Ecto.Migration

  def change do
    create table(:jetton_wallets, primary_key: false) do
      add :address, :binary, primary_key: true
      add :balance, :decimal, default: 0, null: false
      add :raw_address, :binary, null: false

      add :jetton_master_address,
          references(:jetton_masters, column: :address, on_delete: :delete_all, type: :bytea)

      add :wallet_address,
          references(:wallet_credentials, column: :address, on_delete: :delete_all, type: :string)
    end

    create index(:jetton_wallets, [:jetton_master_address, :wallet_address], unique: true)
  end
end
