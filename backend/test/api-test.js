// Simple test client for the Cake Supply Chain API
const API_BASE = "http://localhost:3000";

// Helper function to make API calls
async function apiCall(endpoint, method = "GET", data = null) {
  const options = {
    method,
    headers: {
      "Content-Type": "application/json",
    },
  };

  if (data) {
    options.body = JSON.stringify(data);
  }

  try {
    const response = await fetch(`${API_BASE}${endpoint}`, options);
    const result = await response.json();
    
    console.log(`${method} ${endpoint}:`);
    console.log(JSON.stringify(result, null, 2));
    console.log("---");
    
    return result;
  } catch (error) {
    console.error(`Error calling ${endpoint}:`, error);
    return null;
  }
}

// Test workflow
async function testWorkflow() {
  console.log("🧪 Testing Cake Supply Chain API\n");

  // 1. Check API health
  await apiCall("/");

  // 2. Check contract addresses
  await apiCall("/api/admin/contracts");

  // Example: Set contract addresses (you'll need actual addresses)
  // await apiCall("/api/admin/contracts", "POST", {
  //   "CakeFactory": "0x1234...",
  //   "CakeLifecycleRegistry": "0x5678...",
  //   // ... other contracts
  // });

  // 3. Create a new batch
  const batchData = {
    batchId: 2001,
    maxTemperature: 20,
    minTemperature: -7,
    maxHumidity: 50,
    minHumidity: 20,
    metadataURI: "ipfs://QmExampleHash"
  };
  await apiCall("/api/factory/batch", "POST", batchData);

  // 4. Get batch record
  await apiCall("/api/lifecycle/batch/2001");

  // 5. Submit sensor data
  await apiCall("/api/oracle/sensor-data", "POST", {
    batchId: 2001,
    temperature: 18,
    humidity: 45
  });

  // 6. Get sensor readings
  await apiCall("/api/oracle/batch/2001/readings");

  console.log(" Test workflow completed");
}

// Run the test if this file is executed directly
if (typeof window === "undefined") {
  // Node.js environment
  const fetch = require("node-fetch");
  testWorkflow().catch(console.error);
} else {
  // Browser environment
  console.log("Run testWorkflow() to test the API");
}
