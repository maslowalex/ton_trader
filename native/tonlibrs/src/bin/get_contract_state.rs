use tonlib::client::TonClient;
use tonlib::contract::JettonMasterContract;
use tonlib::contract::TonContractFactory;

use tokio::runtime::Runtime;

async fn method_call() -> anyhow::Result<String> {
    TonClient::set_log_verbosity_level(1);

    let client = TonClient::builder().build().await?;
    let contract_factory = TonContractFactory::builder(&client).build().await?;

    let master_contract =
        contract_factory.get_contract(&"EQDeYzhdAtmEJwLSFxohBmN1kwuQAFD6SyqSprIGznmJ17_e".parse()?);

    let wallet_address = master_contract
        .get_wallet_address(&"UQCvzfTWCeLcud91jaQffRC9sq-IMCYegj_mOZsbKlvYi6pl".parse()?)
        .await?;
    println!("First fetched!");
    // let wallet_address_1 = master_contract
    //     .get_wallet_address(&"UQBr5PE1trssjEIjZuVyNf57Lyb-7Hcwi51d0ImdTqGAD7mU".parse()?)
    //     .await?;
    println!("Second fetched!");

    Ok(wallet_address.to_base64_url())
}

fn main() -> () {
    let runtime = Runtime::new().unwrap();

    runtime.block_on(async {
        match method_call().await {
            Ok(addr) => println!("YOUR ZHEPPE ADDRESS IS {:?}", addr),
            Err(e) => println!("Error: {:?}", e),
        }
    });
}
