import { compileSols, writeOutput } from "./solc-lib";
import Web3 from "web3";
import fs from "fs";
import accounts from "../eth_accounts/accounts.json";
import providers from "../eth_providers/providers.json";

async function main() {
  const [mode, acctTag, shipperAddr, cycleAddr] = process.argv.slice(2);

  if (mode !== "deploy" || !acctTag || !shipperAddr || !cycleAddr) {
    console.error("Usage: deploy accTag adminAddr sensorAddr");
    process.exit(1);
  }

  const output = compileSols(["Shipper"]);
  writeOutput(output, "build");

  const sourceKey = Object.keys(output.contracts)
    .find(k => k.toLowerCase().includes("shipper"))!;
  const artifact  = output.contracts[sourceKey].Shipper as any;
  const { abi, evm } = artifact;

  const web3 = new Web3(providers.ganache);
  const acct = web3.eth.accounts.privateKeyToAccount(
    ((accounts as unknown) as Record<string, { pvtKey: string }>)[acctTag].pvtKey
  );
  web3.eth.accounts.wallet.add(acct);
  web3.eth.defaultAccount = acct.address;

  const Contract = new web3.eth.Contract(abi);
  const tx = Contract.deploy({
    data: "0x" + evm.bytecode.object,
    arguments: [shipperAddr, cycleAddr],
  });

  const inst = await tx.send({ from: acct.address });
  console.log("Shipper deployed at:", inst.options.address);

}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});