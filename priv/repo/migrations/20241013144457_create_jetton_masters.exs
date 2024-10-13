defmodule TonTrader.Repo.Migrations.CreateJettonMasters do
  use Ecto.Migration

  def change do
    create table(:jetton_masters, primary_key: false) do
      add :address, :binary, primary_key: true
      add :name, :string
      add :decimals, :integer
    end
  end
end
