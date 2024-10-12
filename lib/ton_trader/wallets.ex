defmodule TonTrader.Wallets do
  @moduledoc """
  This module is responsible for managing the wallets.
  """

  import Ecto.Query, only: [from: 2]

  alias TonTrader.Repo

  alias TonTrader.Wallets.Wallet
  alias TonTrader.Wallets.WalletCredentials

  alias TonTrader.Wallets.Requests

  @doc """
  Return all existing wallets from database (derived from stored credentials).
  """
  def get_all() do
    WalletCredentials
    |> Repo.all()
    |> Enum.map(fn cred ->
      case restore_wallet(cred) do
        {:ok, wallet} ->
          wallet

        error ->
          error
      end
    end)
  end

  def by_pretty_address(address) do
    WalletCredentials
    |> Repo.get_by(pretty_address: address)
    |> case do
      nil ->
        {:error, :not_found}

      %WalletCredentials{} = cred ->
        restore_wallet(cred)
    end
  end

  @doc """
  Creates a new wallet and inserts the details of restoring it into the database.
  """
  def create_wallet() do
    with %Wallet{} = wallet <- do_create_wallet(),
         {:ok, credentials} <- insert_wallet_credentials(wallet) do
      {:ok, %{wallet: wallet, credentials: credentials}}
    end
  end

  @doc """
  Imports wallet from seed phrase.
  """
  def import_from_mnemonic(mnemonic) do
    do_create_wallet(mnemonic)
  end

  @doc """
  Given mnemonic - restores the wallet, validates the address of the resulting wallet and returns it.
  """
  def restore_wallet(%WalletCredentials{mnemonic: m, address: a} = credentials) do
    with %Ton.KeyPair{} = keypair <- Ton.mnemonic_to_keypair(m),
         %Ton.Wallet{} = wallet <- Ton.create_wallet(keypair.public_key),
         ^a <- Ton.wallet_to_raw_address(wallet) do
      wallet = %Wallet{
        mnemonic: m,
        raw_address: a,
        keypair: keypair,
        wallet: wallet,
        pretty_address: credentials.pretty_address,
        seqno: credentials.seqno
      }

      {:ok, wallet}
    else
      v ->
        # Ecto.Adapters.SQL.query(Repo, "DELETE FROM wallet_credentials WHERE address = $1", [a])

        {:error, :invalid_credentials}
    end
  end

  def insert_wallet_credentials(wallet) do
    %{
      address: wallet.raw_address,
      pretty_address: wallet.pretty_address,
      mnemonic: wallet.mnemonic
    }
    |> WalletCredentials.new()
    |> Repo.insert()
  end

  def sync_seqno(%Wallet{pretty_address: address} = wallet) do
    address
    |> Requests.get_seqno()
    |> TonTrader.RateLimiter.request()
    |> case do
      {:ok, %{status: 200, body: body}} ->
        do_sync_seqno(wallet, body)

      {:ok, %{status: status, body: body}} ->
        {:error, status, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_credentials_seqno(raw_address, new_seqno) do
    {1, _} =
      Repo.update_all(
        from(w in WalletCredentials, where: w.address == ^raw_address),
        set: [seqno: new_seqno]
      )

    :ok
  end

  def prepare_for_transfer([%Wallet{} | _] = wallets) do
    Enum.reduce(wallets, [], fn wallet, acc ->
      case prepare_for_transfer(wallet) do
        %Wallet{} = wallet ->
          [wallet | acc]

        _ ->
          acc
      end
    end)
  end

  def prepare_for_transfer(%Wallet{} = wallet) do
    with {:ok, wallet} <- sync_seqno(wallet),
         {:ok, wallet} <- TonTrader.Transfers.sync_balance(wallet) do
      wallet
    end
  end

  def do_create_wallet(mnemonic \\ generate_mnemonic()) do
    keypair = Ton.mnemonic_to_keypair(mnemonic)
    wallet = Ton.create_wallet(keypair.public_key)

    attrs = %{
      mnemonic: mnemonic,
      raw_address: Ton.wallet_to_raw_address(wallet),
      keypair: keypair,
      wallet: wallet,
      pretty_address: Ton.wallet_to_friendly_address(wallet),
      seqno: 0
    }

    struct!(Wallet, attrs)
  end

  defp do_sync_seqno(%Wallet{seqno: seqno} = wallet, successful_response_body) do
    case Requests.parse_seqno_result(Jason.decode!(successful_response_body)) do
      {:ok, ^seqno} ->
        {:ok, wallet}

      {:ok, new_seqno} ->
        :ok = update_credentials_seqno(wallet.raw_address, new_seqno)

        {:ok, %{wallet | seqno: new_seqno}}

      error ->
        error
    end
  end

  @gen_mnemonic_path Path.join([File.cwd!(), "assets", "generate_mnemonic.mjs"])

  def generate_mnemonic do
    {result, _} = System.cmd("node", [@gen_mnemonic_path])

    String.trim(result)
  end
end
