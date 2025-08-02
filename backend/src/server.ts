import express from "express";
import bodyParser from "body-parser";
import { initWeb3, loadContract, getContract, sendTransaction, callView, defaultAccount } from "./web3-lib";
import { initDatabase, DatabaseService, getDatabase, closeDatabase } from "./database";
;(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// CORS middleware
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization");
  
  if (req.method === "OPTIONS") {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Contract addresses - these should be loaded from deployment
let CONTRACT_ADDRESSES: Record<string, string> = {};

// Initialize contracts and database
const initializeContracts = async () => {
  try {
    // Initialize Database first
    await initDatabase();
    console.log("Database initialized successfully");

    // Initialize Web3
    const { web3, defaultAccount } = initWeb3("acc0");
    console.log("Web3 initialized successfully");

    // Load contract addresses from environment or config
    // For now, using placeholder addresses - replace with actual deployed addresses
    CONTRACT_ADDRESSES = {
      CakeLifecycleRegistry: process.env.LIFECYCLE_REGISTRY_ADDRESS || "",
      CakeFactory: process.env.CAKE_FACTORY_ADDRESS || "",
      Shipper: process.env.SHIPPER_ADDRESS || "",
      Warehouse: process.env.WAREHOUSE_ADDRESS || "",
      SensorOracle: process.env.SENSOR_ORACLE_ADDRESS || "",
      Auditor: process.env.AUDITOR_ADDRESS || "",
      RoleManager: process.env.ROLE_MANAGER_ADDRESS || ""
    };

    // Load contracts if addresses are provided
    for (const [contractName, address] of Object.entries(CONTRACT_ADDRESSES)) {
      if (address) {
        await loadContract(contractName, address);
        console.log(`Loaded ${contractName} at ${address}`);
      }
    }

  } catch (error) {
    console.error("Failed to initialize contracts:", error);
  }
};

// Health check endpoint
app.get("/", (req, res) => {
  res.json({
    message: "Cake Supply Chain API",
    status: "running",
    timestamp: new Date().toISOString()
  });
});

// =============================================================================
// CAKE FACTORY ENDPOINTS
// =============================================================================

// Create a new cake batch
app.post("/api/factory/batch", async (req, res) => {
  try {
    const { batchId, maxTemperature, minTemperature, maxHumidity, minHumidity, metadataURI } = req.body;
    
    if (batchId == null || maxTemperature == null || minTemperature == null || maxHumidity == null || minHumidity == null || metadataURI == null) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    // Call blockchain contract
    const cakeFactory = getContract("CakeFactory");
    const result = await sendTransaction(
      cakeFactory.methods.createBatch(batchId, maxTemperature, minTemperature, maxHumidity, minHumidity, metadataURI)
    );

    console.error("sendTransaction error:", result.error);


    // If blockchain transaction successful, sync to database
    if (result.success) {
      try {
        await DatabaseService.insertCakeBatch({
          batch_id: batchId,
          baker_address: defaultAccount || "unknown",
          metadata_uri: metadataURI,
          min_temp: minTemperature,
          max_temp: maxTemperature,
          min_humidity: minHumidity,
          max_humidity: maxHumidity,
          is_flagged: false,
          status: 'Created'
        });
        console.log(`Batch ${batchId} synced to database`);
      } catch (dbError: any) {
        console.error(`Database sync failed: ${dbError.message}`);
        // Does not affect main flow, only logs error
      }
    }

    res.json({
      success: result.success,
      batchId,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Record quality check
app.post("/api/factory/quality-check", async (req, res) => {
  try {
    const { batchId, snapshotHash } = req.body;
    
    if (!batchId || !snapshotHash) {
      return res.status(400).json({ error: "Missing batchId or snapshotHash" });
    }

    const cakeFactory = getContract("CakeFactory");
    const result = await sendTransaction(
      cakeFactory.methods.recordQualityCheck(batchId, snapshotHash)
    );

    res.json({
      success: result.success,
      batchId,
      snapshotHash,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Handoff to shipper
app.post("/api/factory/handoff", async (req, res) => {
  try {
    const { batchId, shipperAddress } = req.body;
    
    if (!batchId || !shipperAddress) {
      return res.status(400).json({ error: "Missing batchId or shipperAddress" });
    }

    const cakeFactory = getContract("CakeFactory");
    const result = await sendTransaction(
      cakeFactory.methods.handoffToShipper(batchId, shipperAddress)
    );

    res.json({
      success: result.success,
      batchId,
      shipperAddress,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// LIFECYCLE REGISTRY ENDPOINTS
// =============================================================================

// Get cake batch record
app.get("/api/lifecycle/batch/:batchId", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const lifecycle = getContract("CakeLifecycleRegistry");
    const result = await callView(lifecycle.methods.getRecord(batchId));

    if (result.success) {
      const record = result.data;
      res.json({
        success: true,
        batchId,
        record: {
          batchId: record.batchId,
          baker: record.baker,
          shipper: record.shipper,
          warehouse: record.warehouse,
          createdAt: record.createdAt,
          status: record.status,
          maxTemperature: record.maxTemperature,
          minTemperature: record.minTemperature,
          maxHumidity: record.maxHumidity,
          minHumidity: record.minHumidity,
          isFlaged: record.isFlaged,
          metadataURI: record.metadataURI
        }
      });
    } else {
      res.status(404).json({ error: result.error });
    }

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get batch status log
app.get("/api/lifecycle/batch/:batchId/log", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const lifecycle = getContract("CakeLifecycleRegistry");
    const result = await callView(lifecycle.methods.getLog(batchId));

    if (result.success) {
      res.json({
        success: true,
        batchId,
        log: result.data
      });
    } else {
      res.status(404).json({ error: result.error });
    }

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// SHIPPER ENDPOINTS
// =============================================================================

// Record shipping handoff
app.post("/api/shipper/handoff", async (req, res) => {
  try {
    const { batchId, fromActor, toActor, longitude, latitude, snapshotHash } = req.body;
    
    if (!batchId || !fromActor || !toActor || !longitude || !latitude || !snapshotHash) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    const shipper = getContract("Shipper");
    const result = await sendTransaction(
      shipper.methods.handOffLog(batchId, fromActor, toActor, longitude, latitude, snapshotHash)
    );

    res.json({
      success: result.success,
      batchId,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

app.post("/api/shipper/set-oracle", async (req, res) => {
  try {
    const { oracleAddr } = req.body;
    if (!oracleAddr) {
      return res.status(400).json({ error: "Missing oracleAddr" });
    }
    const shipper = getContract("Shipper");

    const result  = await sendTransaction(
      shipper.methods.setOracle(oracleAddr)
    );

    return res.json({
      success: !!result?.success,
      onChain: true,
      transaction: result && {
        hash:        result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed:     result.gasUsed
      }
    });
  } catch (error: any) {
    console.error("setOracle error:", error);
    res.status(500).json({ error: error.message });
  }

});

// Report shipping accident
app.post("/api/shipper/accident", async (req, res) => {
  try {
    const { batchId, actor, accident } = req.body;
    
    if (!batchId || !actor || !accident) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    const shipper = getContract("Shipper");
    const result = await sendTransaction(
      shipper.methods.reportAccident(batchId, actor, accident)
    );

    res.json({
      success: result.success,
      batchId,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Deliver to warehouse
app.post("/api/shipper/deliver", async (req, res) => {
  try {
    const { batchId, warehouseAddress } = req.body;
    
    if (!batchId || !warehouseAddress) {
      return res.status(400).json({ error: "Missing batchId or warehouseAddress" });
    }

    const shipper = getContract("Shipper");
    const result = await sendTransaction(
      shipper.methods.deliveredToWarehouse(batchId, warehouseAddress)
    );

    res.json({
      success: result.success,
      batchId,
      warehouseAddress,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// WAREHOUSE ENDPOINTS
// =============================================================================

// Confirm delivery
app.post("/api/warehouse/confirm-delivery", async (req, res) => {
  try {
    const { batchId } = req.body;
    
    if (!batchId) {
      return res.status(400).json({ error: "Missing batchId" });
    }

    const warehouse = getContract("Warehouse");
    const result = await sendTransaction(
      warehouse.methods.confirmDelivered(batchId)
    );

    res.json({
      success: result.success,
      batchId,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Check quality
app.post("/api/warehouse/quality-check", async (req, res) => {
  try {
    const { batchId, snapshotHash } = req.body;
    
    if (!batchId || !snapshotHash) {
      return res.status(400).json({ error: "Missing batchId or snapshotHash" });
    }

    const warehouse = getContract("Warehouse");
    const result = await sendTransaction(
      warehouse.methods.checkQuality(batchId, snapshotHash)
    );

    res.json({
      success: result.success,
      batchId,
      snapshotHash,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// SENSOR ORACLE ENDPOINTS
// =============================================================================

// Submit sensor data
app.post("/api/oracle/set-shipment", async (req, res) => {

  try {
    const { shipmentAddr } = req.body;
    if (!shipmentAddr) {
      return res.status(400).json({ error: "Missing shipmentAddr" });
    }
    const oracle = getContract("SensorOracle");

    const result  = await sendTransaction(
      oracle.methods.setShipment(shipmentAddr)
    );

    return res.json({
      success: !!result?.success,
      onChain: true,
      transaction: result && {
        hash:        result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed:     result.gasUsed
      }
    });
  } catch (error: any) {
    console.error("setShipment error:", error);
    res.status(500).json({ error: error.message });
  }

});


app.post("/api/oracle/sensor-data", async (req, res) => {
  try {
    const { batchId, timestamp, temperature, humidity } = req.body;
    if (!batchId || temperature === undefined || humidity === undefined) {
      return res.status(400).json({ error: "Missing required sensor data" });
    }

    const batch = await DatabaseService.getCakeBatch(batchId);
    if (!batch) return res.status(404).json({ error: "Unknown batch" });

    /* ---------- local threshold check ---------- */
    const alerts: string[] = [];
    if (temperature > batch.max_temp!) {
      alerts.push(`Temperature too high: ${temperature}°C (max: ${batch.max_temp}°C)`);
    }
    if (temperature < batch.min_temp!) {
      alerts.push(`Temperature too low: ${temperature}°C (min: ${batch.min_temp}°C)`);
    }
    if (humidity > batch.max_humidity!) {
      alerts.push(`Humidity too high: ${humidity}% (max: ${batch.max_humidity}%)`);
    }
    if (humidity < batch.min_humidity!) {
      alerts.push(`Humidity too low: ${humidity}% (min: ${batch.min_humidity}%)`);
    }

    
    if (alerts.length == 0) {
      return res.json({ success: true, onChain: false, alerts: [] });
    }

    for (const alert of alerts) {
      await DatabaseService.logOracleAlert(batchId, "SENSOR_ALERT", alert);
      console.log(`Batch ${batchId} sensor alert: ${alert}`);
    }

    /* ---------- only bad data reaches chain ---------- */
    const oracle  = getContract("SensorOracle");
    const result  = await sendTransaction(
      oracle.methods.submitSensorData(batchId, timestamp, temperature, humidity)
    );

    return res.json({
      success: !!result?.success,
      batchId,
      sensorData: { temperature, humidity },
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Get sensor readings
app.get("/api/oracle/batch/:batchId/readings", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const oracle = getContract("SensorOracle");
    const countResult = await callView(oracle.methods.getReadingCount(batchId));
    
    if (!countResult.success) {
      return res.status(404).json({ error: countResult.error });
    }

    const count = parseInt(countResult.data);
    if (count === 0) {
      return res.json({
        success: true,
        batchId,
        readings: []
      });
    }

    const lastReadingResult = await callView(oracle.methods.getLastReading(batchId));
    
    res.json({
      success: true,
      batchId,
      readingCount: count,
      lastReading: lastReadingResult.success ? {
        timestamp: lastReadingResult.data.timestamp,
        temperature: lastReadingResult.data.temperature,
        humidity: lastReadingResult.data.humidity
      } : null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get alerts for a batch
app.get("/api/oracle/batch/:batchId/alerts", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const oracle = getContract("SensorOracle");
    
    // Note: In a production system, you would query blockchain events
    // For now, we return a placeholder response indicating the endpoint exists
    // but requires additional event querying implementation
    
    res.json({
      success: true,
      batchId,
      message: "Alert querying requires blockchain event indexing - feature planned for future implementation",
      alerts: []
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// AUDITOR ENDPOINTS
// =============================================================================

// Certify audit
app.post("/api/auditor/certify", async (req, res) => {
  try {
    const { batchId, reportHash, comments, verdict } = req.body;
    
    if (!batchId || !reportHash || !comments || verdict === undefined) {
      return res.status(400).json({ error: "Missing required audit parameters" });
    }

    const auditor = getContract("Auditor");
    const result = await sendTransaction(
      auditor.methods.certifyAudit(batchId, reportHash, comments, verdict)
    );

    res.json({
      success: result.success,
      batchId,
      audit: { reportHash, comments, verdict },
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get audit record
app.get("/api/auditor/batch/:batchId", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const auditor = getContract("Auditor");
    const result = await callView(auditor.methods.getAuditRecord(batchId));

    if (result.success) {
      const audit = result.data;
      res.json({
        success: true,
        batchId,
        audit: {
          auditor: audit.auditor,
          auditedAt: audit.auditedAt,
          reportHash: audit.reportHash,
          comments: audit.comments,
          verdict: audit.verdict
        }
      });
    } else {
      res.status(404).json({ error: result.error });
    }

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get comprehensive audit data for a batch
app.get("/api/auditor/batch/:batchId/comprehensive", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    // Get lifecycle records
    const lifecycle = getContract("CakeLifecycleRegistry");
    const batchRecord = await callView(lifecycle.methods.getRecord(batchId));
    
    if (!batchRecord.success) {
      return res.status(404).json({ error: "Batch not found" });
    }

    // Get status logs
    const statusLog = await callView(lifecycle.methods.getLog(batchId));
    
    // Get sensor readings
    const oracle = getContract("SensorOracle");
    const readingCount = await callView(oracle.methods.getReadingCount(batchId));
    let sensorData: { readingCount: number; readings: any[]; lastReading: any } = { 
      readingCount: 0, 
      readings: [], 
      lastReading: null 
    };
    
    if (readingCount.success && parseInt(readingCount.data) > 0) {
      sensorData.readingCount = parseInt(readingCount.data);
      const lastReading = await callView(oracle.methods.getLastReading(batchId));
      if (lastReading.success) {
        sensorData.lastReading = {
          timestamp: lastReading.data.timestamp,
          temperature: lastReading.data.temperature,
          humidity: lastReading.data.humidity
        };
      }
    }

    // Get audit records (if exists)
    const auditor = getContract("Auditor");
    const auditRecord = await callView(auditor.methods.getAuditRecord(batchId));
    let auditData = null;
    if (auditRecord.success) {
      auditData = {
        auditor: auditRecord.data.auditor,
        auditedAt: auditRecord.data.auditedAt,
        reportHash: auditRecord.data.reportHash,
        comments: auditRecord.data.comments,
        verdict: auditRecord.data.verdict
      };
    }

    // Build comprehensive audit data
    const comprehensiveData = {
      success: true,
      batchId,
      auditTimestamp: new Date().toISOString(),
      batchRecord: {
        batchId: batchRecord.data.batchId,
        baker: batchRecord.data.baker,
        shipper: batchRecord.data.shipper,
        warehouse: batchRecord.data.warehouse,
        createdAt: batchRecord.data.createdAt,
        status: batchRecord.data.status,
        maxTemperature: batchRecord.data.maxTemperature,
        minTemperature: batchRecord.data.minTemperature,
        maxHumidity: batchRecord.data.maxHumidity,
        minHumidity: batchRecord.data.minHumidity,
        isFlaged: batchRecord.data.isFlaged,
        metadataURI: batchRecord.data.metadataURI
      },
      statusHistory: statusLog.success ? statusLog.data : [],
      sensorData,
      auditRecord: auditData,
      complianceAnalysis: {
        temperatureCompliance: sensorData.lastReading ? 
          (sensorData.lastReading.temperature >= parseInt(batchRecord.data.minTemperature) && 
           sensorData.lastReading.temperature <= parseInt(batchRecord.data.maxTemperature)) : null,
        humidityCompliance: sensorData.lastReading ? 
          (sensorData.lastReading.humidity >= parseInt(batchRecord.data.minHumidity) && 
           sensorData.lastReading.humidity <= parseInt(batchRecord.data.maxHumidity)) : null,
        isFlagged: batchRecord.data.isFlaged,
        statusCompleted: parseInt(batchRecord.data.status) >= 3 // Delivered or higher
      }
    };

    res.json(comprehensiveData);

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// UTILITY ENDPOINTS
// =============================================================================

// Set contract addresses (for admin use)
app.post("/api/admin/contracts", async (req, res) => {
  try {
    const addresses = req.body;
    
    for (const [contractName, address] of Object.entries(addresses)) {
      if (typeof address === "string" && address) {
        CONTRACT_ADDRESSES[contractName] = address;
        await loadContract(contractName, address);
      }
    }

    res.json({
      success: true,
      message: "Contract addresses updated",
      addresses: CONTRACT_ADDRESSES
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get contract addresses
app.get("/api/admin/contracts", (req, res) => {
  res.json({
    success: true,
    addresses: CONTRACT_ADDRESSES
  });
});

// Clear all database data (ADMIN ONLY - USE WITH CAUTION)
app.post("/api/admin/clear-data", async (req, res) => {
  try {
    const { confirm } = req.body;
    
    // Safety check - require explicit confirmation
    if (confirm !== "YES_CLEAR_ALL_DATA") {
      return res.status(400).json({ 
        error: "Missing or incorrect confirmation", 
        message: "To clear all data, send: { \"confirm\": \"YES_CLEAR_ALL_DATA\" }",
        warning: "This action will permanently delete ALL database records"
      });
    }

    // Clear all database data
    await DatabaseService.clearAllData();

    res.json({
      success: true,
      message: "All database data cleared successfully",
      timestamp: new Date().toISOString(),
      warning: "Database has been reset to brand new state"
    });

    console.log("Database cleared via admin API at", new Date().toISOString());

  } catch (error: any) {
    console.error("Failed to clear database:", error);
    res.status(500).json({ 
      error: "Failed to clear database",
      details: error.message 
    });
  }
});

// =============================================================================
// Database Query API Endpoints
// =============================================================================

// Get all batches (from database)
app.get("/api/database/batches", async (req, res) => {
  try {
    const batches = await DatabaseService.getAllBatches();
    res.json({
      success: true,
      count: batches.length,
      batches
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get specific batch information (from database)
app.get("/api/database/batch/:batchId", async (req, res) => {
  try {
    const batchId = parseInt(req.params.batchId);
    const batch = await DatabaseService.getCakeBatch(batchId);
    
    if (!batch) {
      return res.status(404).json({ error: "Batch not found" });
    }

    res.json({
      success: true,
      batch
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get batch audit records (from database)
app.get("/api/database/batch/:batchId/audit", async (req, res) => {
  try {
    const batchId = parseInt(req.params.batchId);
    const audit = await DatabaseService.getAuditRecord(batchId);
    
    res.json({
      success: true,
      audit: audit || null
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Update batch status (sync to database)
app.patch("/api/database/batch/:batchId/status", async (req, res) => {
  try {
    const batchId = parseInt(req.params.batchId);
    const { status } = req.body;
    
    const validStatuses = ['Created', 'HandedToShipper', 'ArrivedWarehouse', 'Delivered', 'Spoiled', 'Audited'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: "Invalid status value" });
    }

    await DatabaseService.updateBatchStatus(batchId, status);
    
    res.json({
      success: true,
      message: `Batch ${batchId} status updated to ${status}`
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// TEST ENDPOINTS (for development/testing only)
// =============================================================================

// Add sample data for testing
app.post("/api/test/add-sample-data", async (req, res) => {
  try {
    const { batchId } = req.body;
    const testBatchId = batchId || 1001;
    
    // Add sample cake batch
    await DatabaseService.insertCakeBatch({
      batch_id: testBatchId,
      baker_address: "0x742d35Cc6575C59C0AB49749b8b4B2c54E83b0D3",
      metadata_uri: "ipfs://test-metadata",
      min_temp: -7,
      max_temp: 20,
      min_humidity: 20,
      max_humidity: 50,
      is_flagged: false,
      status: 'Created'
    });

    res.json({
      success: true,
      message: `Sample batch ${testBatchId} added to database`,
      batchId: testBatchId
    });

  } catch (error: any) {
    res.status(500).json({ 
      error: "Failed to add sample data",
      details: error.message 
    });
  }
});

// Error handling middleware
app.use((error: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error("Error:", error);
  res.status(500).json({
    error: "Internal server error",
    message: error.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: "Not found",
    path: req.path
  });
});

// Start server
const startServer = async () => {
  await initializeContracts();
  
  app.listen(PORT, () => {
    console.log(`\nCake Supply Chain API Server running on port ${PORT}`);
    console.log(`API Documentation available at http://localhost:${PORT}`);
    console.log(`Contract addresses can be set via POST /api/admin/contracts`);
    console.log(`Database integrated and ready\n`);
  });
};

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  closeDatabase().finally(() => process.exit(1));
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  closeDatabase().finally(() => process.exit(1));
});

// Graceful shutdown handling
const gracefulShutdown = async () => {
  console.log('\nShutting down server...');
  try {
    await closeDatabase();
    console.log('Database connection closed');
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
};

// Handle signals
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

// Start the server
startServer().catch(console.error);

export default app;    console.log("Database initialized successfully");

    // Initialize Web3
    const { web3, defaultAccount } = initWeb3("acc0");
    console.log("Web3 initialized successfully");

    // Load contract addresses from environment or config
    // For now, using placeholder addresses - replace with actual deployed addresses
    CONTRACT_ADDRESSES = {
      CakeLifecycleRegistry: process.env.LIFECYCLE_REGISTRY_ADDRESS || "",
      CakeFactory: process.env.CAKE_FACTORY_ADDRESS || "",
      Shipper: process.env.SHIPPER_ADDRESS || "",
      Warehouse: process.env.WAREHOUSE_ADDRESS || "",
      SensorOracle: process.env.SENSOR_ORACLE_ADDRESS || "",
      Auditor: process.env.AUDITOR_ADDRESS || "",
      RoleManager: process.env.ROLE_MANAGER_ADDRESS || ""
    };

    // Load contracts if addresses are provided
    for (const [contractName, address] of Object.entries(CONTRACT_ADDRESSES)) {
      if (address) {
        await loadContract(contractName, address);
        console.log(`Loaded ${contractName} at ${address}`);
      }
    }

  } catch (error) {
    console.error("Failed to initialize contracts:", error);
  }
};

// Health check endpoint
app.get("/", (req, res) => {
  res.json({
    message: "Cake Supply Chain API",
    status: "running",
    timestamp: new Date().toISOString()
  });
});

// =============================================================================
// CAKE FACTORY ENDPOINTS
// =============================================================================

// Create a new cake batch
app.post("/api/factory/batch", async (req, res) => {
  try {
    const { batchId, maxTemperature, minTemperature, maxHumidity, minHumidity, metadataURI } = req.body;
    
    if (batchId == null || maxTemperature == null || minTemperature == null || maxHumidity == null || minHumidity == null || metadataURI == null) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    // Call blockchain contract
    const cakeFactory = getContract("CakeFactory");
    const result = await sendTransaction(
      cakeFactory.methods.createBatch(batchId, maxTemperature, minTemperature, maxHumidity, minHumidity, metadataURI)
    );

    console.error("sendTransaction error:", result.error);


    // If blockchain transaction successful, sync to database
    if (result.success) {
      try {
        await DatabaseService.insertCakeBatch({
          batch_id: batchId,
          baker_address: defaultAccount || "unknown",
          metadata_uri: metadataURI,
          min_temp: minTemperature,
          max_temp: maxTemperature,
          min_humidity: minHumidity,
          max_humidity: maxHumidity,
          is_flagged: false,
          status: 'Created'
        });
        console.log(`Batch ${batchId} synced to database`);
      } catch (dbError: any) {
        console.error(`Database sync failed: ${dbError.message}`);
        // Does not affect main flow, only logs error
      }
    }

    res.json({
      success: result.success,
      batchId,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Record quality check
app.post("/api/factory/quality-check", async (req, res) => {
  try {
    const { batchId, snapshotHash } = req.body;
    
    if (!batchId || !snapshotHash) {
      return res.status(400).json({ error: "Missing batchId or snapshotHash" });
    }

    const cakeFactory = getContract("CakeFactory");
    const result = await sendTransaction(
      cakeFactory.methods.recordQualityCheck(batchId, snapshotHash)
    );

    res.json({
      success: result.success,
      batchId,
      snapshotHash,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Handoff to shipper
app.post("/api/factory/handoff", async (req, res) => {
  try {
    const { batchId, shipperAddress } = req.body;
    
    if (!batchId || !shipperAddress) {
      return res.status(400).json({ error: "Missing batchId or shipperAddress" });
    }

    const cakeFactory = getContract("CakeFactory");
    const result = await sendTransaction(
      cakeFactory.methods.handoffToShipper(batchId, shipperAddress)
    );

    res.json({
      success: result.success,
      batchId,
      shipperAddress,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// LIFECYCLE REGISTRY ENDPOINTS
// =============================================================================

// Get cake batch record
app.get("/api/lifecycle/batch/:batchId", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const lifecycle = getContract("CakeLifecycleRegistry");
    const result = await callView(lifecycle.methods.getRecord(batchId));

    if (result.success) {
      const record = result.data;
      res.json({
        success: true,
        batchId,
        record: {
          batchId: record.batchId,
          baker: record.baker,
          shipper: record.shipper,
          warehouse: record.warehouse,
          createdAt: record.createdAt,
          status: record.status,
          maxTemperature: record.maxTemperature,
          minTemperature: record.minTemperature,
          maxHumidity: record.maxHumidity,
          minHumidity: record.minHumidity,
          isFlaged: record.isFlaged,
          metadataURI: record.metadataURI
        }
      });
    } else {
      res.status(404).json({ error: result.error });
    }

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get batch status log
app.get("/api/lifecycle/batch/:batchId/log", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const lifecycle = getContract("CakeLifecycleRegistry");
    const result = await callView(lifecycle.methods.getLog(batchId));

    if (result.success) {
      res.json({
        success: true,
        batchId,
        log: result.data
      });
    } else {
      res.status(404).json({ error: result.error });
    }

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// SHIPPER ENDPOINTS
// =============================================================================

// Record shipping handoff
app.post("/api/shipper/handoff", async (req, res) => {
  try {
    const { batchId, fromActor, toActor, longitude, latitude, snapshotHash } = req.body;
    
    if (!batchId || !fromActor || !toActor || !longitude || !latitude || !snapshotHash) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    const shipper = getContract("Shipper");
    const result = await sendTransaction(
      shipper.methods.handOffLog(batchId, fromActor, toActor, longitude, latitude, snapshotHash)
    );

    res.json({
      success: result.success,
      batchId,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Report shipping accident
app.post("/api/shipper/accident", async (req, res) => {
  try {
    const { batchId, actor, accident } = req.body;
    
    if (!batchId || !actor || !accident) {
      return res.status(400).json({ error: "Missing required parameters" });
    }

    const shipper = getContract("Shipper");
    const result = await sendTransaction(
      shipper.methods.reportAccident(batchId, actor, accident)
    );

    res.json({
      success: result.success,
      batchId,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Deliver to warehouse
app.post("/api/shipper/deliver", async (req, res) => {
  try {
    const { batchId, warehouseAddress } = req.body;
    
    if (!batchId || !warehouseAddress) {
      return res.status(400).json({ error: "Missing batchId or warehouseAddress" });
    }

    const shipper = getContract("Shipper");
    const result = await sendTransaction(
      shipper.methods.deliveredToWarehouse(batchId, warehouseAddress)
    );

    res.json({
      success: result.success,
      batchId,
      warehouseAddress,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// WAREHOUSE ENDPOINTS
// =============================================================================

// Confirm delivery
app.post("/api/warehouse/confirm-delivery", async (req, res) => {
  try {
    const { batchId } = req.body;
    
    if (!batchId) {
      return res.status(400).json({ error: "Missing batchId" });
    }

    const warehouse = getContract("Warehouse");
    const result = await sendTransaction(
      warehouse.methods.confirmDelivered(batchId)
    );

    res.json({
      success: result.success,
      batchId,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Check quality
app.post("/api/warehouse/quality-check", async (req, res) => {
  try {
    const { batchId, snapshotHash } = req.body;
    
    if (!batchId || !snapshotHash) {
      return res.status(400).json({ error: "Missing batchId or snapshotHash" });
    }

    const warehouse = getContract("Warehouse");
    const result = await sendTransaction(
      warehouse.methods.checkQuality(batchId, snapshotHash)
    );

    res.json({
      success: result.success,
      batchId,
      snapshotHash,
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// SENSOR ORACLE ENDPOINTS
// =============================================================================

// Submit sensor data
app.post("/api/oracle/sensor-data", async (req, res) => {
  try {
    const { batchId, temperature, humidity } = req.body;
    
    if (!batchId || temperature === undefined || humidity === undefined) {
      return res.status(400).json({ error: "Missing required sensor data" });
    }

    // Submit to blockchain
    const oracle = getContract("SensorOracle");
    const result = await sendTransaction(
      oracle.methods.submitSensorData(batchId, temperature, humidity)
    );

    // Check if exceeds safe ranges and log alerts to database
    if (result.success) {
      try {
        // Get batch safety ranges
        const batch = await DatabaseService.getCakeBatch(batchId);
        if (batch) {
          const alerts: string[] = [];
          
          if (temperature > batch.max_temp!) {
            alerts.push(`Temperature too high: ${temperature}°C (max: ${batch.max_temp}°C)`);
          }
          if (temperature < batch.min_temp!) {
            alerts.push(`Temperature too low: ${temperature}°C (min: ${batch.min_temp}°C)`);
          }
          if (humidity > batch.max_humidity!) {
            alerts.push(`Humidity too high: ${humidity}% (max: ${batch.max_humidity}%)`);
          }
          if (humidity < batch.min_humidity!) {
            alerts.push(`Humidity too low: ${humidity}% (min: ${batch.min_humidity}%)`);
          }

          // Log alerts to database
          for (const alert of alerts) {
            await DatabaseService.logOracleAlert(batchId, "SENSOR_ALERT", alert);
            console.log(`Batch ${batchId} sensor alert: ${alert}`);
          }
        }
      } catch (dbError: any) {
        console.error(`Database alert logging failed: ${dbError.message}`);
        // Does not affect main flow
      }
    }

    res.json({
      success: result.success,
      batchId,
      sensorData: { temperature, humidity },
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get sensor readings
app.get("/api/oracle/batch/:batchId/readings", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const oracle = getContract("SensorOracle");
    const countResult = await callView(oracle.methods.getReadingCount(batchId));
    
    if (!countResult.success) {
      return res.status(404).json({ error: countResult.error });
    }

    const count = parseInt(countResult.data);
    if (count === 0) {
      return res.json({
        success: true,
        batchId,
        readings: []
      });
    }

    const lastReadingResult = await callView(oracle.methods.getLastReading(batchId));
    
    res.json({
      success: true,
      batchId,
      readingCount: count,
      lastReading: lastReadingResult.success ? {
        timestamp: lastReadingResult.data.timestamp,
        temperature: lastReadingResult.data.temperature,
        humidity: lastReadingResult.data.humidity
      } : null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get alerts for a batch
app.get("/api/oracle/batch/:batchId/alerts", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const oracle = getContract("SensorOracle");
    
    // Note: In a production system, you would query blockchain events
    // For now, we return a placeholder response indicating the endpoint exists
    // but requires additional event querying implementation
    
    res.json({
      success: true,
      batchId,
      message: "Alert querying requires blockchain event indexing - feature planned for future implementation",
      alerts: []
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// AUDITOR ENDPOINTS
// =============================================================================

// Certify audit
app.post("/api/auditor/certify", async (req, res) => {
  try {
    const { batchId, reportHash, comments, verdict } = req.body;
    
    if (!batchId || !reportHash || !comments || verdict === undefined) {
      return res.status(400).json({ error: "Missing required audit parameters" });
    }

    const auditor = getContract("Auditor");
    const result = await sendTransaction(
      auditor.methods.certifyAudit(batchId, reportHash, comments, verdict)
    );

    res.json({
      success: result.success,
      batchId,
      audit: { reportHash, comments, verdict },
      transaction: result.success ? {
        hash: result.transactionHash,
        blockNumber: result.blockNumber,
        gasUsed: result.gasUsed
      } : null,
      error: result.error || null
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get audit record
app.get("/api/auditor/batch/:batchId", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    const auditor = getContract("Auditor");
    const result = await callView(auditor.methods.getAuditRecord(batchId));

    if (result.success) {
      const audit = result.data;
      res.json({
        success: true,
        batchId,
        audit: {
          auditor: audit.auditor,
          auditedAt: audit.auditedAt,
          reportHash: audit.reportHash,
          comments: audit.comments,
          verdict: audit.verdict
        }
      });
    } else {
      res.status(404).json({ error: result.error });
    }

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get comprehensive audit data for a batch
app.get("/api/auditor/batch/:batchId/comprehensive", async (req, res) => {
  try {
    const { batchId } = req.params;
    
    // Get lifecycle records
    const lifecycle = getContract("CakeLifecycleRegistry");
    const batchRecord = await callView(lifecycle.methods.getRecord(batchId));
    
    if (!batchRecord.success) {
      return res.status(404).json({ error: "Batch not found" });
    }

    // Get status logs
    const statusLog = await callView(lifecycle.methods.getLog(batchId));
    
    // Get sensor readings
    const oracle = getContract("SensorOracle");
    const readingCount = await callView(oracle.methods.getReadingCount(batchId));
    let sensorData: { readingCount: number; readings: any[]; lastReading: any } = { 
      readingCount: 0, 
      readings: [], 
      lastReading: null 
    };
    
    if (readingCount.success && parseInt(readingCount.data) > 0) {
      sensorData.readingCount = parseInt(readingCount.data);
      const lastReading = await callView(oracle.methods.getLastReading(batchId));
      if (lastReading.success) {
        sensorData.lastReading = {
          timestamp: lastReading.data.timestamp,
          temperature: lastReading.data.temperature,
          humidity: lastReading.data.humidity
        };
      }
    }

    // Get audit records (if exists)
    const auditor = getContract("Auditor");
    const auditRecord = await callView(auditor.methods.getAuditRecord(batchId));
    let auditData = null;
    if (auditRecord.success) {
      auditData = {
        auditor: auditRecord.data.auditor,
        auditedAt: auditRecord.data.auditedAt,
        reportHash: auditRecord.data.reportHash,
        comments: auditRecord.data.comments,
        verdict: auditRecord.data.verdict
      };
    }

    // Build comprehensive audit data
    const comprehensiveData = {
      success: true,
      batchId,
      auditTimestamp: new Date().toISOString(),
      batchRecord: {
        batchId: batchRecord.data.batchId,
        baker: batchRecord.data.baker,
        shipper: batchRecord.data.shipper,
        warehouse: batchRecord.data.warehouse,
        createdAt: batchRecord.data.createdAt,
        status: batchRecord.data.status,
        maxTemperature: batchRecord.data.maxTemperature,
        minTemperature: batchRecord.data.minTemperature,
        maxHumidity: batchRecord.data.maxHumidity,
        minHumidity: batchRecord.data.minHumidity,
        isFlaged: batchRecord.data.isFlaged,
        metadataURI: batchRecord.data.metadataURI
      },
      statusHistory: statusLog.success ? statusLog.data : [],
      sensorData,
      auditRecord: auditData,
      complianceAnalysis: {
        temperatureCompliance: sensorData.lastReading ? 
          (sensorData.lastReading.temperature >= parseInt(batchRecord.data.minTemperature) && 
           sensorData.lastReading.temperature <= parseInt(batchRecord.data.maxTemperature)) : null,
        humidityCompliance: sensorData.lastReading ? 
          (sensorData.lastReading.humidity >= parseInt(batchRecord.data.minHumidity) && 
           sensorData.lastReading.humidity <= parseInt(batchRecord.data.maxHumidity)) : null,
        isFlagged: batchRecord.data.isFlaged,
        statusCompleted: parseInt(batchRecord.data.status) >= 3 // Delivered or higher
      }
    };

    res.json(comprehensiveData);

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// UTILITY ENDPOINTS
// =============================================================================

// Set contract addresses (for admin use)
app.post("/api/admin/contracts", async (req, res) => {
  try {
    const addresses = req.body;
    
    for (const [contractName, address] of Object.entries(addresses)) {
      if (typeof address === "string" && address) {
        CONTRACT_ADDRESSES[contractName] = address;
        await loadContract(contractName, address);
      }
    }

    res.json({
      success: true,
      message: "Contract addresses updated",
      addresses: CONTRACT_ADDRESSES
    });

  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get contract addresses
app.get("/api/admin/contracts", (req, res) => {
  res.json({
    success: true,
    addresses: CONTRACT_ADDRESSES
  });
});

// Clear all database data (ADMIN ONLY - USE WITH CAUTION)
app.post("/api/admin/clear-data", async (req, res) => {
  try {
    const { confirm } = req.body;
    
    // Safety check - require explicit confirmation
    if (confirm !== "YES_CLEAR_ALL_DATA") {
      return res.status(400).json({ 
        error: "Missing or incorrect confirmation", 
        message: "To clear all data, send: { \"confirm\": \"YES_CLEAR_ALL_DATA\" }",
        warning: "This action will permanently delete ALL database records"
      });
    }

    // Clear all database data
    await DatabaseService.clearAllData();

    res.json({
      success: true,
      message: "All database data cleared successfully",
      timestamp: new Date().toISOString(),
      warning: "Database has been reset to brand new state"
    });

    console.log("Database cleared via admin API at", new Date().toISOString());

  } catch (error: any) {
    console.error("Failed to clear database:", error);
    res.status(500).json({ 
      error: "Failed to clear database",
      details: error.message 
    });
  }
});

// =============================================================================
// Database Query API Endpoints
// =============================================================================

// Get all batches (from database)
app.get("/api/database/batches", async (req, res) => {
  try {
    const batches = await DatabaseService.getAllBatches();
    res.json({
      success: true,
      count: batches.length,
      batches
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get specific batch information (from database)
app.get("/api/database/batch/:batchId", async (req, res) => {
  try {
    const batchId = parseInt(req.params.batchId);
    const batch = await DatabaseService.getCakeBatch(batchId);
    
    if (!batch) {
      return res.status(404).json({ error: "Batch not found" });
    }

    res.json({
      success: true,
      batch
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get batch audit records (from database)
app.get("/api/database/batch/:batchId/audit", async (req, res) => {
  try {
    const batchId = parseInt(req.params.batchId);
    const audit = await DatabaseService.getAuditRecord(batchId);
    
    res.json({
      success: true,
      audit: audit || null
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Update batch status (sync to database)
app.patch("/api/database/batch/:batchId/status", async (req, res) => {
  try {
    const batchId = parseInt(req.params.batchId);
    const { status } = req.body;
    
    const validStatuses = ['Created', 'HandedToShipper', 'ArrivedWarehouse', 'Delivered', 'Spoiled', 'Audited'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: "Invalid status value" });
    }

    await DatabaseService.updateBatchStatus(batchId, status);
    
    res.json({
      success: true,
      message: `Batch ${batchId} status updated to ${status}`
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// TEST ENDPOINTS (for development/testing only)
// =============================================================================

// Add sample data for testing
app.post("/api/test/add-sample-data", async (req, res) => {
  try {
    const { batchId } = req.body;
    const testBatchId = batchId || 1001;
    
    // Add sample cake batch
    await DatabaseService.insertCakeBatch({
      batch_id: testBatchId,
      baker_address: "0x742d35Cc6575C59C0AB49749b8b4B2c54E83b0D3",
      metadata_uri: "ipfs://test-metadata",
      min_temp: -7,
      max_temp: 20,
      min_humidity: 20,
      max_humidity: 50,
      is_flagged: false,
      status: 'Created'
    });

    res.json({
      success: true,
      message: `Sample batch ${testBatchId} added to database`,
      batchId: testBatchId
    });

  } catch (error: any) {
    res.status(500).json({ 
      error: "Failed to add sample data",
      details: error.message 
    });
  }
});

// Error handling middleware
app.use((error: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error("Error:", error);
  res.status(500).json({
    error: "Internal server error",
    message: error.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: "Not found",
    path: req.path
  });
});

// Start server
const startServer = async () => {
  await initializeContracts();
  
  app.listen(PORT, () => {
    console.log(`\nCake Supply Chain API Server running on port ${PORT}`);
    console.log(`API Documentation available at http://localhost:${PORT}`);
    console.log(`Contract addresses can be set via POST /api/admin/contracts`);
    console.log(`Database integrated and ready\n`);
  });
};

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  closeDatabase().finally(() => process.exit(1));
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  closeDatabase().finally(() => process.exit(1));
});

// Graceful shutdown handling
const gracefulShutdown = async () => {
  console.log('\nShutting down server...');
  try {
    await closeDatabase();
    console.log('Database connection closed');
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
};

// Handle signals
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

// Start the server
startServer().catch(console.error);

export default app;
