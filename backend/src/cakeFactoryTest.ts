import fs   from "fs";
import path from "path";
import Web3 from "web3";
import { violates, CakeReading } from "./validateReadings";

// ── 1. build artefact ────────────────────────────────────────────
import providers from "../../eth_providers/providers.json";
import accounts  from "../../eth_accounts/accounts.json";

const factoryArtefact = require("../../build/CakeFactory.json")
const factoryAbi = factoryArtefact.CakeFactory.CakeFactory.abi as any


// … your existing imports and setup …

(async () => {
  /* connect */
  const web3   = new Web3(providers.ganache);
  const acct   = web3.eth.accounts.privateKeyToAccount(accounts.acc0.pvtKey);
  web3.eth.accounts.wallet.add(acct);
  web3.eth.defaultAccount = acct.address;

  const [,, factoryAddr, shipperAddr] = process.argv;
  if (!factoryAddr || !shipperAddr) {
    throw new Error("Usage: ts-node … <factory-address> <shipper-address>");
  }

  const factory = new web3.eth.Contract(factoryAbi, factoryAddr);

  // 1) Create the batch (as before)
  await factory.methods
    .createBatch(102, 20, -10, 5, "ipfs://QmTestHash123")
    .send({ from: acct.address, gas: 2_000_000 });
  console.log("Batch 102 created");

  // 2) Now hand it off to your shipper…
  await factory.methods
    .handoffToShipper(102, shipperAddr)
    .send({ from: acct.address, gas: 2_000_000 });
  console.log(`Batch 102 handed off to ${shipperAddr}`);

  // 3) Verify the on-chain mapping
  const info = await factory.methods.batches(102).call();
  console.log("Batch info:", info);

  // 4) Fetch all BatchHandoff events
  const handoffs = await factory.getPastEvents("BatchHandoff", {
    fromBlock: 0,
    toBlock: "latest"
  });
  handoffs.forEach(e => {
    console.log(
      `→ handoff ${e.returnValues.batchId}: from ${e.returnValues.from} to ${e.returnValues.to}`,
      `at ${new Date(e.returnValues.timestamp * 1e3).toISOString()}`
    );
  });
})();
