// src/deployAll.ts
import { compileSols, writeOutput } from "./solc-lib";
import Web3 from "web3";
import fs from "fs";
import path from "path";
import providers from "../eth_providers/providers.json";
import accounts  from "../eth_accounts/accounts.json";

// ------- 1. describe your deploy order & wiring --------------------
interface PlanItem {
  name: string;                       // contract name
  ctor: Array<any>;                   // constructor args
  after?: Array<[string,string,any[]]>;// [callTarget, fn, args]
}

/** EDIT ME: add or reorder to fit your system */
const deployPlan = [
  { name: "RoleManager", ctor: ["$Admin"] },
  { name: "CakeFactory", ctor: ["$Admin"] },
  { name: "CakeLifecycleRegistry", ctor: ["$CakeFactory"] },
  { name: "Shipper", ctor: ["$ShipperEOA", "$CakeLifecycleRegistry"] },
  { name: "Warehouse", ctor: ["$RoleManager"] },
  { name: "SensorOracle", ctor: ["$Admin", "$SensorEOA"],
    after: [["SensorOracle","setShipment",["$Shipper"]]] },
  { name: "Auditor", ctor: ["$Admin","$RoleManager","$CakeLifecycleRegistry"] }
];


// --------------------------------------------------------------------

async function main() {
  const [mode, acctTag, adminAddr, sensorAddr] = process.argv.slice(2);
  if (mode !== "deploy") {
    console.error("Usage: deploy accTag adminAddr sensorAddr");
    process.exit(1);
  }

  /* 1. compile everything under contracts/ ------------------------- */
  const out = compileSols([
    "RoleManager",
    "CakeFactory",
    "CakeLifecycleRegistry",
    "Shipper",
    "Warehouse",
    "SensorOracle",
    "Auditor"
  ]);
  if (!out?.contracts) {
    console.error("Solidity compile failed; check import paths.");
    process.exit(1);
  }
  writeOutput(out, "build");                       // optional

  /* 2. connect to node -------------------------------------------- */
  const web3 = new Web3(providers.ganache);
  const acctInfo = (accounts as Record<string, any>)[acctTag];
  if (!acctInfo || typeof acctInfo.pvtKey !== "string") {
    throw new Error(`Account tag '${acctTag}' not found or invalid in accounts.json`);
  }
  const acct = web3.eth.accounts.privateKeyToAccount(acctInfo.pvtKey);
  web3.eth.accounts.wallet.add(acct);
  web3.eth.defaultAccount = acct.address;

  /* 3. run the deployment plan ------------------------------------ */
  const addr: Record<string, string> = {
    $Admin:  adminAddr,      // from CLI
    $Sensor: sensorAddr,     // from CLI
    $SensorEOA: sensorAddr,  // synonym for convenience
    $ShipperEOA: adminAddr   // or pass a 5th CLI arg if you prefer
  };

  for (const item of deployPlan) {
    const sourceKey = Object.keys(out.contracts)
                     .find(k => new RegExp(item.name,"i").test(k))!;
    const art = out.contracts[sourceKey][item.name];
    const C  = new web3.eth.Contract(art.abi as any);

    // replace placeholders ($Something) in ctor
    const ctorArgs = item.ctor.map(a =>
        typeof a === "string" && a.startsWith("$") ? addr[a] : a);

    const inst = await C.deploy({
        data: "0x"+art.evm.bytecode.object,
        arguments: ctorArgs
      }).send({ from: acct.address });
    addr[`$${item.name}`] = inst.options.address ?? "";
    console.log(`Deployed ${item.name} → ${inst.options.address ?? ""}`);

    // post-deploy wiring
    if (item.after) {
      for (const [targetName, fn, args] of item.after) {
        const targetAddr = addr[`$${targetName}`];
        const targetKey = Object.keys(out.contracts).find(k => k.toLowerCase().includes(String(targetName).toLowerCase()))!;
        const targetAbi  = out.contracts[targetKey][String(targetName)].abi;
        const target = new web3.eth.Contract(targetAbi as any, targetAddr);
        const wireArgs = Array.isArray(args)
          ? args.map(a => typeof a === "string" && a.startsWith("$") ? addr[a] : a)
          : [typeof args === "string" && args.startsWith("$") ? addr[args] : args];
        if (typeof fn === "string") {
          await (target.methods as any)[fn](...wireArgs).send({ from: acct.address });
        } else {
          throw new Error(`Method name 'fn' must be a string, got: ${typeof fn}`);
        }
        console.log(`${targetName}.${fn}(${wireArgs.join(",")})`);
      }
    }
  }

  console.log("\nDeployment summary:");
  Object.entries(addr).forEach(([k,v]) => k.startsWith("$") && console.log(`${k.slice(1)}: ${v}`));
}

main().catch(e => { console.error(e); process.exit(1); });
