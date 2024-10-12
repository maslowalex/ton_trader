use num_bigint::BigUint;

use std::time::SystemTime;
use tonlib::cell::{ArcCell, EMPTY_ARC_CELL};

use tonlib::address::TonAddress;
use tonlib::cell::BagOfCells;
use tonlib::client::TonClient;
use tonlib::client::TonClientInterface;
use tonlib::contract::JettonMasterContract;
use tonlib::contract::TonContractFactory;
use tonlib::message::JettonTransferMessage;

use tonlib::message::TransferMessage;
use tonlib::mnemonic::KeyPair;
use tonlib::mnemonic::Mnemonic;
use tonlib::wallet::TonWallet;
use tonlib::wallet::WalletVersion;

use tokio::runtime::Runtime;

use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    // TonClient::set_log_verbosity_level(1);
    let runtime = Runtime::new().unwrap();

    runtime.block_on(async move {
        let seqno: i32 = 85;

        let self_address: TonAddress = "EQDtcAEyDrVPPRcJXjy0b7rgO96rHpLAU1rzWvQbo5pLL9ff"
            .parse()
            .unwrap();

        let mnemonic_str = "hybrid capital topic try scale half syrup slight gospel chicken rude stereo december tragic aware embrace decade siren utility kitten tiny basket eternal practice";

        let mnemonic: Mnemonic = Mnemonic::from_str(mnemonic_str, &None).unwrap();
        let key_pair: KeyPair = mnemonic.to_key_pair().unwrap();

        let jetton_master_address: TonAddress = "EQDeYzhdAtmEJwLSFxohBmN1kwuQAFD6SyqSprIGznmJ17_e"
            .parse()
            .unwrap();

        let client = TonClient::default().await?;

        let dest_jetton: TonAddress = "EQBkwsN4sWHm_stwIihehDvj5giCW4RILFkb7TzUdUPyz7iK".parse()?;
        let dest: TonAddress = "EQAAodFXhgUHsx6UeEAS7Y4jD-5RU9hKG-kK4ThhXLQQcKvo".parse()?;

        let self_jetton_wallet_addr: TonAddress = "EQB9fnjfz5W3s6DYfclSc5PMfVStk2HvcskRQ1znLdwzDrbD".parse()?;
        let wallet = TonWallet::derive(0, WalletVersion::V4R2, &key_pair, 698_983_191)?;

        let jetton_amount = BigUint::from(7500000000000u64);

        let jetton_transfer = JettonTransferMessage::new(&dest_jetton, &jetton_amount).with_response_destination(&self_address).with_forward_payload(&BigUint::from(10000u64), EMPTY_ARC_CELL.clone()).build()?;

        let ton_amount = BigUint::from(300000000u64); // 0.002 TON

        let transfer = TransferMessage::new(&self_jetton_wallet_addr, &ton_amount)
            .with_data(jetton_transfer)
            .build()?;
        let now = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)?
            .as_secs() as u32;
        let transfer: Vec<ArcCell> = vec![transfer.into()];
        let body = wallet.create_external_body(now + 60, seqno.try_into().unwrap(), &transfer)?;
        let signed = wallet.sign_external_body(&body)?;
        let wrapped = wallet.wrap_signed_body(signed, false)?;
        let boc = BagOfCells::from_root(wrapped);
        let tx: Vec<u8> = boc.serialize(true)?;

        let hash = client.send_raw_message_return_hash(tx.as_slice()).await?;

        Ok::<(), Box<dyn Error>>(())
    })?;
    Ok(())
}
