import SensorOracleJson from './abi/SensorOracle.json';
import { ethers } from "ethers";
import { config } from "dotenv"
import { ORACLE_ABI } from "../src/abi/SensorOracle.json"
import fs from "fs"
import path from 'path';

config()

const readingPath = path.resolve(process.cwd(), "data/Reading.json");
const reading = JSON.parse(
  fs.readFileSync(readingPath, "utf-8")
) as { Readings: Array<{
  batchId: number;
  timestamp: number;
  temperature: number;
  humidity: number;
}>};

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.INFURA_URL);
  const wallet = new ethers.Wallet( process.env.PRIVATE_KEY!, provider )

  const oracle = new ethers.Contract(
    
  )
}
