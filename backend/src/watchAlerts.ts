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


