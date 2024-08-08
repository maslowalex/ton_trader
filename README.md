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

## Parse from txt file

```elixir
mnemonic = File.read!("mnemonic.txt") |> String.trim() |> String.split("\n ") |> Enum.map(&String.trim/1) |> Enum.join(" ")

wallet = TonTrader.Wallets.import_from_mnemonic(mnemonic)
```