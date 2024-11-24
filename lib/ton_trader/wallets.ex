defmodule TonTrader.Wallets do
  @moduledoc """
  This module is responsible for managing the wallets.
  """

  import Ecto.Query, warn: false

  alias TonTrader.Repo

  alias TonTrader.Wallets.Wallet
  alias TonTrader.Wallets.WalletCredentials
  alias TonTrader.Wallets.JettonMaster
  alias TonTrader.Wallets.JettonWallet

  alias TonTrader.TonlibRs

  alias TonTrader.Wallets.Requests

  def start_wallet_server(opts) do
    DynamicSupervisor.start_child(
      TonTrader.WalletsDynamicSupervisor,
      {TonTrader.Wallets.Server, opts}
    )
  end

  @doc """
  Return all existing wallets from database (derived from stored credentials).
  """
  def get_all() do
    Enum.map(all_credentials(), fn cred ->
      case restore_wallet(cred) do
        {:ok, wallet} ->
          wallet

        error ->
          error
      end
    end)
  end

  def all_ton_wallet_addresses do
    WalletCredentials
    |> select([w], w.pretty_address)
    |> Repo.all()
  end

  def all_credentials() do
    WalletCredentials
    |> preload([:jetton_wallets])
    |> Repo.all()
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
    with %Wallet{} = wallet <- do_create_wallet(mnemonic),
         {:ok, credentials} <- insert_wallet_credentials(wallet) do
      {:ok, %{wallet: wallet, credentials: credentials}}
    end
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
        seqno: credentials.seqno,
        balance: credentials.balance
      }

      {:ok, wallet}
    else
      _ ->
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

  def prepare_for_transfer(%Wallet{pretty_address: pretty_address} = wallet) do
    with {:ok, wallet} <- sync_seqno(wallet),
         {:ok, balance} <- TonTrader.Transfers.sync_balance(pretty_address) do
      Map.put(wallet, :balance, balance)
    end
  end

  @spec do_create_wallet(binary()) :: struct()
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

  def derive_jetton_wallets(%JettonMaster{} = master, ton_addresses) do
    mapping = TonlibRs.ton_to_jetton_addresses(master.address, ton_addresses)

    for {ton_address, jetton_address} <- mapping do
      case by_pretty_address(ton_address) do
        {:ok, ton_wallet} ->
          insert_jetton_wallet(ton_wallet, master, jetton_address)

        error ->
          error
      end
    end
  end

  def insert_master_wallet(attrs) do
    %JettonMaster{}
    |> JettonMaster.changeset(attrs)
    |> Repo.insert()
  end

  def all_jetton_masters do
    Repo.all(JettonMaster)
  end

  def insert_jetton_wallet(
        %Wallet{} = ton_wallet,
        %JettonMaster{} = jetton_master,
        jetton_wallet_address
      ) do
    {:ok, raw_address} = Ton.Address.friendly_address_to_raw_address(jetton_wallet_address)

    %JettonWallet{
      jetton_master_address: jetton_master.address,
      wallet_address: ton_wallet.raw_address,
      raw_address: raw_address
    }
    |> JettonWallet.changeset(%{address: jetton_wallet_address, balance: 0})
    |> Repo.insert()
  end

  def update_jetton_wallet(jetton_wallet, attrs) do
    jetton_wallet
    |> JettonWallet.changeset(attrs)
    |> Repo.update()
  end

  def get_wallets_for_master(master_name) do
    JettonWallet
    |> join(:inner, [jw], _ in assoc(jw, :jetton_master))
    |> where([_, jm], jm.name == ^master_name)
    |> Repo.all()
  end
end
