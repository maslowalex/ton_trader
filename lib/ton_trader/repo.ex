defmodule TonTrader.Repo do
  use Ecto.Repo,
    otp_app: :ton_trader,
    adapter: Ecto.Adapters.Postgres
end
