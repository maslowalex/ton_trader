use anyhow::{anyhow, Result};
use num_bigint::BigUint;
use std::time::SystemTime;

use tonlib::address::TonAddress;
use tonlib::cell::BagOfCells;
use tonlib::client::TonClient;
use tonlib::client::TonClientInterface;
use tonlib::message::TransferMessage;
use tonlib::mnemonic::KeyPair;
use tonlib::mnemonic::Mnemonic;
use tonlib::wallet::TonWallet;
use tonlib::wallet::WalletVersion;

use tonlib::cell::ArcCell;

use tokio::runtime::Runtime;

fn main() -> Result<()> {
    let runtime = Runtime::new()?;

    runtime.block_on(async move {
        create_simple_transfer().await.unwrap();
    });

    Ok(())
}

async fn create_simple_transfer() -> anyhow::Result<()> {
    let mnemonic: Mnemonic = Mnemonic::from_str("old pledge damage sport few alone access bracket birth angry green enable cross three energy vanish era salon derive general victory danger weasel all", &None)?;
    let key_pair = mnemonic.to_key_pair()?;
    let seqno = 2;

    let client = TonClient::default().await?;
    let wallet = TonWallet::derive(0, WalletVersion::V4R2, &key_pair, 698_983_191)?;

    println!("Wallet address: {}", wallet.address.to_base64_url());

    let dest: TonAddress = "UQBt1y-4gtQNmUjUYC-5TURrxIfApxBP-W85OAbogVmSBM5F".parse()?;
    let value = BigUint::from(6666666u64); // 0.01 TON
    let transfer = TransferMessage::new(&dest, &value).build()?;
    let now = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)?
        .as_secs() as u32;
    let transfer: Vec<ArcCell> = vec![transfer.into()];
    let body = wallet.create_external_body(now + 60, seqno, &transfer)?;
    let signed = wallet.sign_external_body(&body)?;
    let wrapped = wallet.wrap_signed_body(signed, true)?;
    let boc = BagOfCells::from_root(wrapped);
    let tx = boc.serialize(false)?;
    let hash = client.send_raw_message_return_hash(tx.as_slice()).await?;

    Ok(())
}
