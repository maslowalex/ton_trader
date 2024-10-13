use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use num_bigint::BigUint;
use std::collections::HashMap;

use std::time::SystemTime;
use tonlib::cell::{ArcCell, EMPTY_ARC_CELL};

use tonlib::address::TonAddress;
use tonlib::cell::BagOfCells;
use tonlib::client::TonClient;
use tonlib::contract::JettonMasterContract;
use tonlib::contract::TonContractFactory;
use tonlib::message::JettonTransferMessage;

use tonlib::message::TransferMessage;
use tonlib::mnemonic::KeyPair;
use tonlib::mnemonic::Mnemonic;
use tonlib::wallet::TonWallet;
use tonlib::wallet::WalletVersion;

use rustler::{Error, NifStruct};
use tokio::runtime::Runtime;

type TonToJetton = HashMap<String, String>;

#[derive(Debug, NifStruct)]
#[module = "TonTrader.TonlibRs.JettonTransfer"]
struct JettonTransfer {
    pub report_wallet_address: String,
    pub destination_jetton_wallet_address: String,
    pub sender_jetton_address: String,
    pub sender_wallet_mnemonic: String,
    pub sender_wallet_seqno: i32,
    pub jetton_amount: u64,
    pub ton_forward_amount: u64,
    pub ton_amount: u64,
}

#[rustler::nif]
fn get_wallet_address(
    jetton_contract_addr: String,
    ton_addresses: Vec<String>,
) -> Result<TonToJetton, Error> {
    TonClient::set_log_verbosity_level(1);

    let rt = Runtime::new().unwrap();

    rt.block_on(async {
        let mut jetton_addresses = HashMap::new();

        let client = TonClient::default()
            .await
            .map_err(|_| Error::Atom("ton_client_error"))?;

        let contract_factory = TonContractFactory::builder(&client)
            .build()
            .await
            .map_err(|_| Error::Atom("contract_factory_error"))?;
        let contract = contract_factory.get_contract(
            &jetton_contract_addr
                .parse()
                .map_err(|_| Error::Atom("jetton_contract_addr_error"))?,
        );

        for ton_address in ton_addresses {
            let owner_address = TonAddress::from_base64_url(&ton_address).map_err(|_| {
                Error::Term(Box::new(format!(
                    "Invalid address passed: {}",
                    &ton_address
                )))
            })?;

            let wallet_address = contract.get_wallet_address(&owner_address).await;

            match wallet_address {
                Ok(wallet_address) => {
                    let wallet_address = wallet_address.to_base64_url();
                    jetton_addresses.insert(ton_address, wallet_address);
                }
                Err(_err) => {
                    println!("Invalid address: {:?}", ton_address);
                }
            }
        }

        Ok(jetton_addresses)
    })
}

#[rustler::nif]
fn jetton_transfer_boc(transfer_msg: JettonTransfer) -> Result<String, Error> {
    let JettonTransfer {
        destination_jetton_wallet_address,
        report_wallet_address,
        sender_jetton_address,
        sender_wallet_mnemonic,
        sender_wallet_seqno,
        jetton_amount,
        ton_forward_amount,
        ton_amount,
    } = transfer_msg;

    let self_address: TonAddress = report_wallet_address
        .parse()
        .map_err(|_| Error::Atom("invalid_report_address"))?;

    let mnemonic: Mnemonic = Mnemonic::from_str(&sender_wallet_mnemonic, &None).unwrap();
    let key_pair: KeyPair = mnemonic.to_key_pair().unwrap();

    let dest_jetton: TonAddress = destination_jetton_wallet_address
        .parse()
        .map_err(|_| Error::Atom("invalid_jetton_destination_address"))?;

    let self_jetton_wallet_addr: TonAddress = sender_jetton_address
        .parse()
        .map_err(|_| Error::Atom("invalid_sender_jetton_address"))?;
    let wallet = TonWallet::derive(0, WalletVersion::V4R2, &key_pair, 698_983_191)
        .map_err(|_| Error::Atom("wallet_derive_error"))?;

    let jetton_amount = BigUint::from(jetton_amount);

    let jetton_transfer = JettonTransferMessage::new(&dest_jetton, &jetton_amount)
        .with_response_destination(&self_address)
        .with_forward_payload(&BigUint::from(ton_forward_amount), EMPTY_ARC_CELL.clone())
        .build()
        .map_err(|_| Error::Atom("jetton_transfer_message_error"))?;

    let ton_amount = BigUint::from(ton_amount);

    let transfer = TransferMessage::new(&self_jetton_wallet_addr, &ton_amount)
        .with_data(jetton_transfer)
        .build()
        .map_err(|_| Error::Atom("transfer_message_error"))?;
    let now = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .map_err(|_| Error::Atom("time_error"))?
        .as_secs() as u32;
    let transfer: Vec<ArcCell> = vec![transfer.into()];
    let body = wallet
        .create_external_body(now + 60, sender_wallet_seqno.try_into().unwrap(), &transfer)
        .map_err(|_| Error::Atom("external_message_building_error"))?;
    let signed = wallet
        .sign_external_body(&body)
        .map_err(|_| Error::Atom("external_message_sign_error"))?;
    let wrapped = wallet
        .wrap_signed_body(signed, false)
        .map_err(|_| Error::Atom("wraping_error"))?;
    let boc = BagOfCells::from_root(wrapped);
    let tx: Vec<u8> = boc
        .serialize(true)
        .map_err(|_| Error::Atom("serialization_error"))?;

    Ok(STANDARD.encode(tx.as_slice()))
}

rustler::init!("Elixir.TonTrader.TonlibRs");
