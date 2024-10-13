defmodule TonTrader.TonlibRs.JettonTransfer do
  @moduledoc """
  The struct for the jetton transfer parameters encapsulation.

  ## The meaning of the fields:

  - `report_wallet_address` - the address of the wallet that will receive the report about the transaction outcome.
  - `destination_jetton_wallet_address` - the JETTON wallet address of receiver.
  - `sender_jetton_address` - the JETTON wallet address of sender.
  - `sender_wallet_mnemonic` - the mnemonic of the sender wallet.
  - `sender_wallet_seqno` - the current seqno of the sender wallet.
  - `jetton_amount` - the amount of JETTON to transfer.
  - `ton_forward_amount` - the amount of TON to forward usually the default is good.
  - `ton_amount` - the amount of TON to transfer usually the default is good.

  The TON amount is amout / 10^9 as well as the JETTON amount.
  """

  @enforce_keys [
    :report_wallet_address,
    :destination_jetton_wallet_address,
    :sender_jetton_address,
    :sender_wallet_mnemonic,
    :sender_wallet_seqno,
    :jetton_amount,
    :ton_forward_amount,
    :ton_amount
  ]
  defstruct [
    :report_wallet_address,
    :destination_jetton_wallet_address,
    :sender_jetton_address,
    :sender_wallet_mnemonic,
    :sender_wallet_seqno,
    :jetton_amount,
    ton_forward_amount: 10000,
    ton_amount: 300_000_000
  ]
end
