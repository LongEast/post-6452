import fs from "fs";
import path from "path";
import Web3 from "web3";
import { violates, CakeReading } from "./validateReading";
import sensorJson from "../build/SensorOracle.json";

import providers from "../eth_providers/providers.json";
import accounts  from "../eth_accounts/accounts.json";
const oracleAbi      = (sensorJson as any)["SensorOracle"].SensorOracle.abi;


(async () => {
  // 1. connect ----------------------------------------------------------------
  const web3  = new Web3(providers.ganache);
  const acct  = web3.eth.accounts.privateKeyToAccount(accounts.acc0.pvtKey);
  web3.eth.accounts.wallet.add(acct);
  web3.eth.defaultAccount = acct.address;

  // 2. load JSON --------------------------------------------------------------
  const cakesPath = path.resolve(process.cwd(), "data/cakes.json");
  const { cakes } = JSON.parse(fs.readFileSync(cakesPath, "utf-8")) as
                    { cakes: CakeReading[] };

  // 3. filter -----------------------------------------------------------------
  const badOnes = cakes.filter(r => violates(r) !== null);
  console.log(`Found ${badOnes.length} violations out of ${cakes.length}`);

  if (badOnes.length === 0) return;

  // 4. attach contract --------------------------------------------------------
  const oracleAddr = process.argv[2];             // pass on CLI
  const oracle     = new web3.eth.Contract(
                       oracleAbi as any, oracleAddr);

  // 5. push each violation ----------------------------------------------------
  for (const r of badOnes) {
    console.log(`→ pushing batch ${r.batchId}`);
    await oracle.methods
            .submitSensorData(r.batchId, r.temperature, r.humidity)
            .send({ from: acct.address });
  }
})();
