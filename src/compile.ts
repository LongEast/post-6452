// src/compile.ts
import path from 'path';
import fs from 'fs-extra';
import solc from 'solc';

// Step 1: 获取合约源代码目录
const contractsPath = path.resolve(__dirname, '../contracts');
const buildPath = path.resolve(__dirname, '../build');

// Step 2: 清空之前的 build 输出目录
fs.removeSync(buildPath);
fs.ensureDirSync(buildPath);

// Step 3: 构造输入对象（包含多个 .sol 文件）
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

// Step 4: 编译所有合约
const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Step 5: 写入每个合约的编译结果
for (const fileName in output.contracts) {
  for (const contractName in output.contracts[fileName]) {
    const contract = output.contracts[fileName][contractName];
    const outputFile = path.resolve(buildPath, `${contractName}.json`);
    fs.outputJSONSync(outputFile, contract, { spaces: 2 });
    console.log(`✅ Compiled: ${contractName}`);
  }
}
