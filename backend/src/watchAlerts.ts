#!/usr/bin/env ts-node
/* ---------------------------------------------
   Live monitor for SensorOracle → Shipper flow
   --------------------------------------------- */

import { ethers } from "ethers";
import { config } from "dotenv";
import path from 'path';
import fs from "fs"

config();                                   // loads .env

  const abiPathOracle = path.resolve(__dirname, "../../artifacts/SensorOracle.json");
  const abiPathShipper = path.resolve(__dirname, "../../artifacts/Shipper.json");

  const { abi: ORACLE_ABI } = JSON.parse(fs.readFileSync(abiPathOracle, "utf8"));
  const { abi: SHIPPER_ABI } = JSON.parse(fs.readFileSync(abiPathShipper, "utf8"));


// ---- 2.  Prep provider & contract objects ----
const provider = new ethers.JsonRpcProvider(process.env.INFURA_URL);

const oracle  = new ethers.Contract(process.env.ORACLE_ADDRESS!,  ORACLE_ABI,  provider);
const shipper = new ethers.Contract(process.env.SHIPPER_ADDRESS!, SHIPPER_ABI, provider);

/* ---------------------------------------------
   Subscribe to ThresholdAlert
--------------------------------------------- */
oracle.on("ThresholdAlert",
  async (batchId, ts, reason) => {
    console.log(`  batch=${batchId} ts=${ts} reason=${reason}`);

    // Optional sanity-check: read shipper state
    const count   = await shipper.alertCount(batchId);
    const lastTs  = await shipper.alertLogs(batchId);
    const flagged = await shipper.hasFlagged(batchId);
    console.log(`   Shipper → count=${count} lastTs=${lastTs} flagged=${flagged}`);
  });

console.log("  Watching alerts…");
process.stdin.resume();          // keep Node alive