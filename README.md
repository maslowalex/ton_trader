# TonTrader

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## How to create a wallet

```elixir
%{wallet: wallet} = TonTrader.Wallets.create_wallet()
```

## How to make a transfer from wallet to address
- Use the wallet from previous step, note that 1 is not eq to 1 TON in this example, it's a smallest fraction of it.
```elixir
TonTrader.Transfers.transfer(wallet, "UQCWrFEjv3IDTnflpr1G3xIrgiZ9gMpO9OWezVp3P1Gm-So4", 1)
```

## Jettons transfer is quite tricky!
You can check out the working demo in jetton_transfer.rs file.

# Note on the wallet "deployment" process (dont' skip this):
In order for wallet to be "Activated" there is essential chain of steps needs to be performed!

- First, you need to create a special kind of mnemonic, the algorithm proposed in Elixir `Ton` library is not sufficient, we are using the `tonweb-mnemonic` Javascript library for this purpose!

- Secondly, for newly created wallets it is essential to send first TON to it with `bounce: false` parameter! If you don't do that the wallet will never switch to an "Active" state and you'll lost the funds you sent to it.

## Parse from txt file

```elixir
mnemonic = File.read!("mnemonic.txt") |> String.trim() |> String.split("\n ") |> Enum.map(&String.trim/1) |> Enum.join(" ")

wallet = TonTrader.Wallets.import_from_mnemonic(mnemonic)
```

## TODO
- Jettons transfer
- Transactions observer
