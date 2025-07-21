import { ethers } from "ethers";
import { config } from "dotenv"
import fs from "fs"
import path from 'path';

// Load .env into process.env
config()


//
// Step 1: Read in our sensor data JSON file
//
const readingPath = path.resolve(process.cwd(), "data/Readings.json");

// Expecting {"Readings":[{batchId, timestamp, temperature, humidity}, …]}
const { Readings } = JSON.parse(
  fs.readFileSync(readingPath, "utf-8")
) as { Readings: Array<{
  batchId: number;
  timestamp: number;
  temperature: number;
  humidity: number;
}>};

async function main() {
  //
  // Step 2: Connect to Ethereum
  //
  const provider = new ethers.JsonRpcProvider(process.env.INFURA_URL);

  // Create a signer (wallet) from our private key in the .env
  const wallet = new ethers.Wallet( process.env.PRIVATE_KEY!, provider )

  //
  // Step 3: Load the Oracle ABI
  //
  // We read the compiled contract artifact JSON and pull out its "abi" field
  const abiPath = path.resolve(__dirname, "../../artifacts/SensorOracle.json");
  const { abi: ORACLE_ABI } = JSON.parse(fs.readFileSync(abiPath, "utf8"));


  //
  // Step 4: Instantiate the Oracle contract
  //
  const oracle = new ethers.Contract(
    process.env.ORACLE_ADDRESS!,
    ORACLE_ABI,
    wallet
  )

  //
  // Step 5: Loop through each reading and submit it on-chain
  //

  for (const r of Readings) {
    console.log("Submitting:", r);
    const tx = await oracle.submitSensorData(
      r.batchId, r.timestamp, r.temperature, r.humidity,
      { gasLimit: 100_000 }
    );
    console.log(" tx hash:", tx.hash);
    // Wait for transaction confirmation
    await tx.wait();
  }
}

// Run & catch any top-level errors
main().catch((err) => {
  console.error("Script failed:", err);
  process.exit(1);
});