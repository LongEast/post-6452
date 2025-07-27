import fs   from "fs";
import path from "path";
import Web3 from "web3";
import { violates, CakeReading } from "./validateReadings";

// 1 — load build artefact (needs "resolveJsonModule": true in tsconfig)
import sensorJson from "../../build/SensorOracle.json";

// 2 — load runtime config
import providers from "../../eth_providers/providers.json";
import accounts  from "../../eth_accounts/accounts.json";

// artefact now has .abi directly (thanks to new writeOutput)
const oracleAbi = (sensorJson as any).abi;

(async () => {
  /* 1. connect ---------------------------------------------------- */
  const web3 = new Web3(providers.ganache);
  const acct = web3.eth.accounts.privateKeyToAccount(accounts.acc0.pvtKey);
  web3.eth.accounts.wallet.add(acct);
  web3.eth.defaultAccount = acct.address;

  /* 2. load JSON -------------------------------------------------- */
  const cakesPath = path.resolve("data/cakes.json");
  const { cakes } = JSON.parse(fs.readFileSync(cakesPath, "utf8")) as {
    cakes: CakeReading[];
  };

  /* 3. filter ----------------------------------------------------- */
  const bad = cakes.filter(r => violates(r) !== null);
  console.log(`Found ${bad.length} violations out of ${cakes.length}`);
  if (!bad.length) return;

  /* 4. attach contract ------------------------------------------- */
  const oracleAddr = process.argv[2];        // passed on CLI
  const oracle = new web3.eth.Contract(oracleAbi as any, oracleAddr);

  /* 5. push each violation --------------------------------------- */
  for (const r of bad) {
    console.log(`→ pushing batch ${r.batchId}`);
    await oracle.methods
      .submitSensorData(r.batchId, r.temperature, r.humidity)
      .send({ from: acct.address });
  }
})();
