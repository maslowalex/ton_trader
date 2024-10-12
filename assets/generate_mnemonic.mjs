import tonMnemonic from "tonweb-mnemonic";

const mnemonic = await tonMnemonic.generateMnemonic();

console.log(mnemonic.join(" "));