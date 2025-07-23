// compile the Solidity contracts and output the compiled JSON files to the build directory
import path from 'path';
import fs from 'fs-extra';
import solc from 'solc';

// Step 1: get the paths for contracts and build directories
const contractsPath = path.resolve(__dirname, '../contracts');
const buildPath = path.resolve(__dirname, '../build');

// Step 2: clear the previous build output directory
fs.removeSync(buildPath);
fs.ensureDirSync(buildPath);

// Step 3: construct the input object (containing multiple .sol files)
const sources: Record<string, { content: string }> = {};
fs.readdirSync(contractsPath).forEach(file => {
  if (file.endsWith('.sol')) {
    const filePath = path.resolve(contractsPath, file);
    const source = fs.readFileSync(filePath, 'utf8');
    sources[file] = { content: source };
  }
});

const input = {
  language: 'Solidity',
  sources,
  settings: {
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode'],
      },
    },
  },
};

// Step 4: compile all contracts
const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Step 5: write each contract's compilation result
for (const fileName in output.contracts) {
  for (const contractName in output.contracts[fileName]) {
    const contract = output.contracts[fileName][contractName];
    const outputFile = path.resolve(buildPath, `${contractName}.json`);
    fs.outputJSONSync(outputFile, contract, { spaces: 2 });
    console.log(`Compiled: ${contractName}`);
  }
}
