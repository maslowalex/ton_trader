use tonlib::client::TonClient;
use tonlib::contract::JettonMasterContract;
use tonlib::contract::TonContractFactory;

use tokio::runtime::Runtime;

async fn method_call() -> anyhow::Result<TonContractFactory> {
    TonClient::set_log_verbosity_level(1);

    let client = TonClient::builder().build().await?;
    let contract_factory = TonContractFactory::builder(&client).build().await?;

    let master_contract =
        contract_factory.get_contract(&"EQDeYzhdAtmEJwLSFxohBmN1kwuQAFD6SyqSprIGznmJ17_e".parse()?);

    let data = master_contract.get_jetton_data().await?;

    dbg!(data);

    Ok(contract_factory)
}

fn main() -> () {
    let runtime = Runtime::new().unwrap();

    runtime.block_on(async {
        method_call().await.unwrap();
    });
}
