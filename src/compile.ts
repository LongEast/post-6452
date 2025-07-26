import { compileSols, writeOutput } from "./solc-lib";

/** Add every contract (without .sol) you want in the build folder */
const output = compileSols([
  "SensorOracle",          // contracts/SensorOracle.sol
  // "Shipment",            // contracts/Shipment.sol  ← add others if needed
]);

writeOutput(output, "build");     // produces build/SensorOracle.json
console.log("Contracts compiled to build/");
