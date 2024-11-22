defmodule TonTrader.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TonTraderWeb.Telemetry,
      TonTrader.Repo,
      {DNSCluster, query: Application.get_env(:ton_trader, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TonTrader.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TonTrader.Finch},
      {Task.Supervisor, name: TonTrader.TaskSupervisor},
      # Start a worker by calling: TonTrader.Worker.start_link(arg)
      # {TonTrader.Worker, arg},
      # Start to serve requests, typically the last entry
      TonTraderWeb.Endpoint,
      TonTrader.RateLimiter,
      TonTrader.Wallets.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TonTrader.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TonTraderWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
