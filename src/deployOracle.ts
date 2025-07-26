import { compileSols, writeOutput } from "./solc-lib";
import Web3 from "web3";
import fs from "fs";
import accounts from "../eth_accounts/accounts.json";
import providers from "../eth_providers/providers.json";

async function main() {
  const [mode, acctTag, adminAddr, sensorAddr] = process.argv.slice(2);

  if (mode !== "deploy" || !acctTag || !adminAddr || !sensorAddr) {
    console.error("Usage: deploy accTag adminAddr sensorAddr");
    process.exit(1);
  }

  /* ---------- 1. compile & write ABI ----------------------------- */
  const output = compileSols(["SensorOracle"]);
  writeOutput(output, "build");

  const sourceKey = Object.keys(output.contracts)
    .find(k => k.toLowerCase().includes("sensororacle"))!;
  const artifact  = output.contracts[sourceKey].SensorOracle as any;
  const { abi, evm } = artifact;

  /* ---------- 2. connect to node -------------------------------- */
  const web3 = new Web3(providers.ganache);
  const acct = web3.eth.accounts.privateKeyToAccount(
    ((accounts as unknown) as Record<string, { pvtKey: string }>)[acctTag].pvtKey
  );
  web3.eth.accounts.wallet.add(acct);
  web3.eth.defaultAccount = acct.address;

  /* ---------- 3. deploy ----------------------------------------- */
  const Contract = new web3.eth.Contract(abi);
  const tx = Contract.deploy({
    data: "0x" + evm.bytecode.object,
    arguments: [adminAddr, sensorAddr],
  });

  const inst = await tx.send({ from: acct.address });   // ← no gas field
  console.log("SensorOracle deployed at:", inst.options.address);

}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
