// backend/src/sendTx.ts
import { JsonRpcProvider, Wallet, Contract } from "ethers";
import fs from "fs";
import path from "path";
import accounts from "../../eth_accounts/accounts.json";

const argv = require("minimist")(process.argv.slice(2));
type AccountKey = "acc0" | "acc1" | "acc2";
const { contract: name, fn, args, from } = argv as { contract: string; fn: string; args: string; from: AccountKey };

if (!name || !fn || !args || !from) {
  console.error("Usage: ts-node sendTx.ts --contract <Name> --fn <fnName> --args '[...]' --from <accKey>");
  process.exit(1);
}

// 1) Connect to Ganache RPC
const provider = new JsonRpcProvider("http://localhost:8546");

// 2) Load the private key for “from” and create a signer
const wallet = new Wallet(accounts[from].pvtKey, provider);

// 3) Read the deployed address & ABI from your build output
const json = JSON.parse(
  fs.readFileSync(path.resolve(__dirname, `../../build/${name}.json`), "utf8")
);
const address = json[name][name].address as string;
const abi     = json[name][name].abi as any[];

// 4) Instantiate the Contract with the signer
const contract = new Contract(address, abi, wallet);

(async () => {
  const parsedArgs = JSON.parse(args);
  console.log(`→ ${name}.${fn}(${parsedArgs.join(", ")})`);
  const tx = await (contract as any)[fn](...parsedArgs);
  console.log(`  tx hash: ${tx.hash}`);
  await tx.wait();
  console.log("✓ mined");
})();
