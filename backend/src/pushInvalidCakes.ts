import fs   from "fs";
import path from "path";
import Web3 from "web3";
import { violates, CakeReading } from "./validateReadings";

// ── 1. build artefact ────────────────────────────────────────────
import providers from "../../eth_providers/providers.json";
import accounts  from "../../eth_accounts/accounts.json";

const sensorArtefact = require("../../build/SensorOracle.json");
const oracleAbi = sensorArtefact.abi as any;

// ── 2. main async wrapper ────────────────────────────────────────
(async () => {
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

  /* filter */
  const bad = cakes.filter(r => violates(r) !== null);
  console.log(`Found ${bad.length} violations out of ${cakes.length}`);
  if (!bad.length) return;

  /* 4. build the contract – Web3 v4 + TS */
  const oracleAddr = process.argv[2];
  if (!oracleAddr) throw new Error("Usage: ts-node … <oracle-address>");

  const oracle = new web3.eth.Contract(
    oracleAbi,      // ABI  – make sure this really is an array
    oracleAddr      // address (string) goes here
  );




  /* push each violation */
  for (const r of bad) {
    console.log(`→ pushing batch ${r.batchId}`);
    await oracle.methods
      .submitSensorData(r.batchId, r.temperature, r.humidity) // add timestamp if your ABI needs it
      .send({ from: acct.address });
  }
})();
