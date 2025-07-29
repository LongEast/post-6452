import Web3 from "web3";
const fs = require("fs");
const path = require("path");
import providers from "../../eth_providers/providers.json";
import accounts from "../../eth_accounts/accounts.json";

// Web3 instance
let web3: Web3;
let defaultAccount: string;

// Contract interfaces
interface ContractInfo {
  address: string;
  abi: any;
  instance: any;
}

// Contract instances store
const contracts: Record<string, ContractInfo> = {};

// Initialize Web3 connection
export const initWeb3 = (accountTag: string = "acc0") => {
  web3 = new Web3(providers.ganache);
  
  const acctInfo = (accounts as Record<string, any>)[accountTag];
  if (!acctInfo || typeof acctInfo.pvtKey !== "string") {
    throw new Error(`Account tag '${accountTag}' not found or invalid in accounts.json`);
  }
  
  const acct = web3.eth.accounts.privateKeyToAccount(acctInfo.pvtKey);
  web3.eth.accounts.wallet.add(acct);
  web3.eth.defaultAccount = acct.address;
  defaultAccount = acct.address;
  
  console.log(`Web3 initialized with account: ${defaultAccount}`);
  return { web3, defaultAccount };
};

// Load contract from build directory
export const loadContract = (contractName: string, contractAddress: string) => {
  try {
    const buildPath = path.resolve(`build/${contractName}.json`);
    const contractData = JSON.parse(fs.readFileSync(buildPath, "utf8"));
    
    // Find the contract ABI in the JSON structure
    let abi: any;
    for (const fileName in contractData) {
      if (contractData[fileName][contractName]) {
        abi = contractData[fileName][contractName].abi;
        break;
      }
    }
    
    if (!abi) {
      throw new Error(`ABI not found for contract ${contractName}`);
    }
    
    const instance = new web3.eth.Contract(abi, contractAddress);
    
    contracts[contractName] = {
      address: contractAddress,
      abi,
      instance
    };
    
    console.log(`Contract ${contractName} loaded at ${contractAddress}`);
    return instance;
  } catch (error) {
    console.error(`Error loading contract ${contractName}:`, error);
    throw error;
  }
};

// Get contract instance
export const getContract = (contractName: string) => {
  const contract = contracts[contractName];
  if (!contract) {
    throw new Error(`Contract ${contractName} not loaded. Call loadContract first.`);
  }
  return contract.instance;
};

// Helper function to send transaction
export const sendTransaction = async (
  contractMethod: any,
  fromAddress?: string
) => {
  try {
    const from = fromAddress || defaultAccount;
    const result = await contractMethod.send({ from });
    return {
      success: true,
      transactionHash: result.transactionHash,
      blockNumber: result.blockNumber,
      gasUsed: result.gasUsed
    };
  } catch (error: any) {
    console.error("Transaction failed:", error);
    return {
      success: false,
      error: error.message || "Transaction failed"
    };
  }
};

// Helper function to call view functions
export const callView = async (contractMethod: any) => {
  try {
    const result = await contractMethod.call();
    return {
      success: true,
      data: result
    };
  } catch (error: any) {
    console.error("View call failed:", error);
    return {
      success: false,
      error: error.message || "View call failed"
    };
  }
};

// Get account balance
export const getBalance = async (address: string) => {
  const balance = await web3.eth.getBalance(address);
  return web3.utils.fromWei(balance, "ether");
};

// Get current gas price
export const getGasPrice = async () => {
  return await web3.eth.getGasPrice();
};

export { web3, defaultAccount };