// src/solc-lib.ts
// ------------------------------------------------------------
// Tiny helper used by compile.ts and deploy scripts
// ------------------------------------------------------------
import fs   from "fs";
import path from "path";
import fse  from "fs-extra";
import solc from "solc";

/* ------------------------------------------------------------------ */
/* import resolver                                                    */
/* ------------------------------------------------------------------ */
const findImports = (p: string): { contents?: string; error?: string } => {
  const nodeMod = path.resolve("node_modules", p);
  if (fs.existsSync(nodeMod)) return { contents: fs.readFileSync(nodeMod, "utf8") };

  const local = path.resolve("contracts", p);
  if (fs.existsSync(local))   return { contents: fs.readFileSync(local, "utf8") };

  return { error: `File not found: ${p}` };
};

/* ------------------------------------------------------------------ */
/* compile the given contract names (without .sol)                    */
/* ------------------------------------------------------------------ */
export const compileSols = (names: string[]) => {
  const sources: Record<string, { content: string }> = {};

  for (const name of names) {
    const srcPath = path.join("contracts", `${name}.sol`);
    try {
      sources[`${name}.sol`] = { content: fs.readFileSync(srcPath, "utf8") };
    } catch (e) {
      console.error(`Missing file: ${srcPath}`);
      throw e;
    }
  }

  const input = {
    language: "Solidity",
    sources,
    settings: { outputSelection: { "*": { "*": ["*"] } } }
  };

  const output = JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));

  const errs = output.errors?.filter((e: any) => e.severity === "error") || [];
  if (errs.length) {
    console.error("Compile errors:\n");
    errs.forEach((e: any) => console.error(e.formattedMessage));
    throw new Error("Solidity compile failed");
  }
  return output;
};

/* ------------------------------------------------------------------ */
/* write each contract’s artefact into build/<Contract>.json          */
/* ------------------------------------------------------------------ */
export const writeOutput = (compiled: any, buildPath: string) => {
  fse.ensureDirSync(buildPath);

  for (const src in compiled.contracts) {
    for (const contractName in compiled.contracts[src]) {
      const artefact = compiled.contracts[src][contractName];
      const dest     = path.join(buildPath, `${contractName}.json`);
      fse.outputJsonSync(dest, artefact, { spaces: 2 });
      console.log("Written:", dest);
    }
  }
};
