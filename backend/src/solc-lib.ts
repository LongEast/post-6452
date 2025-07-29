/// SPDX-License-Identifier: UNLICENSED

const fs = require('fs')
const fsExtra = require('fs-extra')
const path = require('path')
const solc = require('solc')

/**
 * Find files to import
 * @param {string} path Path to import
 * @returns {any} Contract code as an object
 */
const findImports = (p: string): any => {
  try {
    // 1) try node_modules (OpenZeppelin, etc.)
    const nm = path.resolve("node_modules", p);
    if (fs.existsSync(nm)) return { contents: fs.readFileSync(nm, "utf8") };

    // 2) try local contracts folder (./Foo.sol, ../bar/Baz.sol)
    const local = path.resolve("contracts", p);
    if (fs.existsSync(local)) return { contents: fs.readFileSync(local, "utf8") };

    return { error: `File not found: ${p}` };
  } catch (e: any) {
    return { error: e.message };
  }
};


/**
 * Writes contracts from the compiled sources into JSON files
 * @param {any} compiled Object containing the compiled contracts
 * @param {string} buildPath Path of the build folder
 */
export const writeOutput = (compiled: any, buildPath: string) => {
    fsExtra.ensureDirSync(buildPath)    // Make sure directory exists

    for (let contractFileName in compiled.contracts) {
        const contractName = contractFileName.replace('.sol', '')
        console.log('Writing: ', contractName + '.json to ' + buildPath)
        console.log(path.resolve(buildPath, contractName + '.json'))
        fsExtra.outputJsonSync(
            path.resolve(buildPath, contractName + '.json'),
            // This writes just the relevant abi, evm.bytecode
            // [contractFileName][contractName] if want to simplify
            compiled.contracts
        )
    }
}

/**
 * Compile Solidity contracts
 * @param {Array<string>} names List of contract names
 * @return An object with compiled contracts
 */
export const compileSols = (names: string[]): any => {
    // Collection of Solidity source files
    interface SolSourceCollection {
        [key: string]: any
    }

    let sources: SolSourceCollection = {}

    names.forEach((value: string, index: number, array: string[]) => {
        let file = fs.readFileSync(`contracts/${value}.sol`, 'utf8')
        sources[value] = {
            content: file
        }
    })

    // sources = {
    //   "MyToken.sol": {
    //     content: "contract MyToken { ... }"
    //   },
    //   "Utils.sol": {
    //     content: "library Utils { ... }"
    //   }
    // }
    let input = {
        language: 'Solidity',
        sources,
        settings: {
            outputSelection: {
                '*': {
                    '*': ['*']
                }
            },
              optimizer: {
                enabled: true,
        runs: 200
  }, 
            evmVersion: 'berlin' //Uncomment this line if using Ganache GUI
        }
    }

    // Compile all contracts
    try {
        return JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }))
    } catch (error) {
        try {
        return JSON.parse(solc.compile(JSON.stringify(input), { import: findImports }));
        } catch (err: any) {
            console.error("\nSolc threw:\n", err);
            throw err;                  // propagate so deployAll exits fast
        }

    }
}