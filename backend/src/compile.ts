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

writeOutput(output, "build");
console.log("Contracts compiled to build/");
