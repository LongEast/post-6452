import fs   from "fs";
import path from "path";
import Web3 from "web3";
import { violates, CakeReading } from "./validateReadings";

// ── 1. build artefact ────────────────────────────────────────────
import providers from "../../eth_providers/providers.json";
import accounts  from "../../eth_accounts/accounts.json";

const sensorArtefact = require("../../build/SensorOracle.json");
const oracleAbi = sensorArtefact.SensorOracle.SensorOracle.abi as any;



// ── 2. main async wrapper ────────────────────────────────────────
(async () => {

  console.log(Array.isArray(oracleAbi)) // should log true

  /* connect */
  const web3   = new Web3(providers.ganache);
  const acct   = web3.eth.accounts.privateKeyToAccount(accounts.acc0.pvtKey);
  web3.eth.accounts.wallet.add(acct);
  web3.eth.defaultAccount = acct.address;

  /* read JSON */
  const cakesPath = path.resolve("backend/data/cakes.json");
  const { cakes } = JSON.parse(fs.readFileSync(cakesPath, "utf8")) as {
    cakes: CakeReading[];
  };

  console.log("cakes:", cakes)

  /* filter */
  const bad = cakes.filter(r => violates(r) !== null);
  console.log(`Found ${bad.length} violations out of ${cakes.length}`);
  if (!bad.length) return;

  /* 4. build the contract*/
  // Pass the SensorOracle address as argument when trying to run
  const oracleAddr = process.argv[2];
  if (!oracleAddr) throw new Error("Usage: ts-node … <oracle-address>");

  const oracle = new web3.eth.Contract(
    oracleAbi,      // ABI
    oracleAddr      // address (string)
  );

  // ── 3½. remember where we started ───────────────────────────────
  const startBlock = await web3.eth.getBlockNumber();   //  ← place this **before** the for-loop

  /* push each violation */
  for (const r of bad) {
    console.log(`→ pushing batch ${r.batchId}`);
    await oracle.methods
      .submitSensorData(r.batchId, r.temperature, r.humidity)
      .send({ from: acct.address, gas: 2_000_000 });
  }

  // ── 5. verify alerts were emitted ────────────────────────────────
  const topic0 = web3.utils.keccak256(
    "ThresholdAlert(uint256,uint256,string)"
  );

  const logs = await web3.eth.getPastLogs({
    address: oracleAddr,
    fromBlock: startBlock + 1,   // only the brand-new pushes
    toBlock:   "latest",
    topics:    [topic0]
  });

  console.log("Alert logs found:", logs.length);
  logs.forEach(l => {
    const batchId = web3.utils.hexToNumber(l.topics[1]);
    console.log(`batch ${batchId} logHash=${l.transactionHash}`);
  });


})();
