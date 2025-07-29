import { compileSols, writeOutput } from "./solc-lib";

const output = compileSols([
  "RoleManager",
  "CakeFactory",
  "CakeLifecycleRegistry",
  "Shipper",
  "IShipmentAlertSink",
  "Warehouse",
  "SensorOracle",
  "Auditor"
]);
console.log(output)
writeOutput(output, "build");
console.log("Contracts compiled to build/");
