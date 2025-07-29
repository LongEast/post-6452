// src/deployAll.ts
import { compileSols, writeOutput } from "./solc-lib";
import Web3 from "web3";
import fs from "fs";
import path from "path";
import providers from "../../eth_providers/providers.json";
import accounts  from "../../eth_accounts/accounts.json";

// ------- 1. describe your deploy order & wiring --------------------
interface PlanItem {
  name: string;                       // contract name
  ctor: Array<any>;                   // constructor args
  after?: Array<[string,string,any[]]>;// [callTarget, fn, args]
}

const deployPlan: PlanItem[] = [
  /* 1) deploy RoleManager first */
  { name: "RoleManager", ctor: ["$Admin"] },

  /* 2) deploy the central registry next */
  { name: "CakeLifecycleRegistry", ctor: ["$Admin"] },

  /* 3) now CakeFactory can receive the registry address */
  { name: "CakeFactory", ctor: ["$Admin", "$CakeLifecycleRegistry"] },

  /* 4) business contracts that depend on the registry */
  { name: "Shipper",   ctor: ["$ShipperEOA", "$CakeLifecycleRegistry"] },
  { name: "Warehouse", ctor: ["$Admin",      "$CakeLifecycleRegistry"] },

  /* 5) SensorOracle + wiring to the Shipper */
  { name: "SensorOracle",
    ctor:  ["$Admin", "$SensorEOA"],
    after: [["SensorOracle", "setShipment", ["$Shipper"]]]
  },

  /* 6) Auditor depends on both RoleManager and Registry */
  { name: "Auditor",
    ctor: ["$Admin", "$RoleManager", "$CakeLifecycleRegistry"]
  }
];



// --------------------------------------------------------------------

async function main() {
  // mode: deploy
  // acctTag: "acc0"
  // adminAddr: "0xAdminAddr"
  // sensorAddr: "0xSensorAddr"
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
  writeOutput(out, "build");

  /* 2. connect to node -------------------------------------------- */
  const web3 = new Web3(providers.ganache);
  // look up in the eth_accounts/accounts.json
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
        const isPlaceholder = (x: unknown): x is `$${string}` =>
          typeof x === "string" && x.startsWith("$");

        const wireArgs = Array.isArray(args)
          ? args.map(a => isPlaceholder(a) ? addr[a] : a)
          : [isPlaceholder(args) ? addr[args] : args];

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