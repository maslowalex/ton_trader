use std::collections::HashMap;
use tonlib::address::TonAddress;
use tonlib::client::TonClient;
use tonlib::contract::JettonMasterContract;
use tonlib::contract::TonContractFactory;

use rustler::{Env, Error, NifStruct, Resource, ResourceArc};
use tokio::runtime::Runtime;

type TonToJettonMap = HashMap<String, String>;

#[rustler::nif]
fn get_wallet_address(
    contract_addr: String,
    ton_addresses: Vec<String>,
) -> Result<TonToJettonMap, Error> {
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
            &contract_addr
                .parse()
                .map_err(|_| Error::Atom("contract_addr_error"))?,
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
                Err(err) => {
                    println!("Invalid address: {:?}", ton_address);
                }
            }
        }

        Ok(jetton_addresses)
    })
}

rustler::init!("Elixir.TonTrader.TonlibRs");
