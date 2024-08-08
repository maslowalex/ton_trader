defmodule TonTrader.Wallets do
  @moduledoc """
  This module is responsible for managing the wallets.
  """

  alias TonTrader.Repo

  alias TonTrader.Wallets.Wallet
  alias TonTrader.Wallets.WalletCredentials

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
        pretty_address: credentials.pretty_address
      }

      {:ok, wallet}
    else
      v ->
        {:error, :invalid_credentials, v}
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

  defp do_create_wallet() do
    mnemonic = Ton.generate_mnemonic()
    keypair = Ton.mnemonic_to_keypair(mnemonic)
    wallet = Ton.create_wallet(keypair.public_key)

    attrs = %{
      mnemonic: mnemonic,
      raw_address: Ton.wallet_to_raw_address(wallet),
      keypair: keypair,
      wallet: wallet,
      pretty_address: Ton.wallet_to_friendly_address(wallet)
    }

    struct!(Wallet, attrs)
  end

  def dummy_transfer(r) do
    {:ok, to_address} = Ton.parse_address("UQBr5PE1trssjEIjZuVyNf57Lyb-7Hcwi51d0ImdTqGAD7mU")

    params = [
      seqno: 0,
      bounce: true,
      secret_key: r.keypair.secret_key,
      value: 10,
      to_address: to_address,
      timeout: 60,
      comment: "blat"
    ]

    Ton.create_transfer_boc(r.wallet, params)
    |> Base.encode64()
    |> send_boc_request()
    |> Finch.request(TonTrader.Finch)
  end

  defp send_boc_request(boc) do
    Finch.build(
      :post,
      "https://toncenter.com/api/v2/sendBoc",
      [{"Content-Type", "application/json"}, {"accept", "application/json"}],
      Jason.encode!(%{boc: boc})
    )
  end
end
