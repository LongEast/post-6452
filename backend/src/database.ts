// backend/src/database.ts
import { Database as SQLiteDatabase } from 'sqlite3';
import { open, Database } from 'sqlite';
import * as fs from 'fs';
import * as path from 'path';

let db: Database | null = null;

// Initialize database connection
export async function initDatabase(): Promise<Database> {
  if (db) return db;

  // Create database file
  const dbPath = path.join(__dirname, '../data/blockchain_cake.db');
  
  db = await open({
    filename: dbPath,
    driver: SQLiteDatabase
  });

  // Execute database schema files
  await createTables();
  
  console.log('Database connection established:', dbPath);
  return db;
}

// Create all tables
async function createTables() {
  if (!db) throw new Error('Database not initialized');

  const schemaDir = path.join(__dirname, '../database/schemes');
  const schemaFiles = [
    'cake_batches.sql',
    'audit_records.sql', 
    'handoffs.sql',
    'oracle_alerts.sql',
    'quality_checks.sql',
    'shipping_accidents.sql',
    'status_logs.sql'
  ];

  for (const file of schemaFiles) {
    const filePath = path.join(schemaDir, file);
    if (fs.existsSync(filePath)) {
      const sql = fs.readFileSync(filePath, 'utf8');
      await db.exec(sql);
      console.log(`Table created: ${file}`);
    }
  }
}

// Get database instance
export function getDatabase(): Database {
  if (!db) throw new Error('Database not initialized, please call initDatabase() first');
  return db;
}

// Close database connection
export async function closeDatabase() {
  if (db) {
    await db.close();
    db = null;
    console.log('Database connection closed');
  }
}

// Database operation interfaces
export interface CakeBatch {
  batch_id: number;
  created_at: string;
  baker_address: string;
  metadata_uri?: string;
  min_temp?: number;
  max_temp?: number;
  min_humidity?: number;
  max_humidity?: number;
  is_flagged: boolean;
  status: 'Created' | 'HandedToShipper' | 'ArrivedWarehouse' | 'Delivered' | 'Spoiled' | 'Audited';
}

export interface AuditRecord {
  batch_id: number;
  auditor: string;
  audited_at: string;
  report_hash: string;
  comments?: string;
  verdict: 'PASS' | 'FAIL' | 'UNCLEAR';
}

// Database operation functions
export class DatabaseService {
  
  // Insert cake batch
  static async insertCakeBatch(batch: Omit<CakeBatch, 'created_at'>): Promise<void> {
    const db = getDatabase();
    await db.run(
      `INSERT INTO cake_batches 
       (batch_id, created_at, baker_address, metadata_uri, min_temp, max_temp, min_humidity, max_humidity, is_flagged, status)
       VALUES (?, datetime('now'), ?, ?, ?, ?, ?, ?, ?, ?)`,
      [batch.batch_id, batch.baker_address, batch.metadata_uri, batch.min_temp, batch.max_temp, 
       batch.min_humidity, batch.max_humidity, batch.is_flagged, batch.status]
    );
  }

  // Get cake batch
  static async getCakeBatch(batchId: number): Promise<CakeBatch | null> {
    const db = getDatabase();
    const result = await db.get('SELECT * FROM cake_batches WHERE batch_id = ?', [batchId]);
    return result || null;
  }

  // Update batch status
  static async updateBatchStatus(batchId: number, status: CakeBatch['status']): Promise<void> {
    const db = getDatabase();
    await db.run('UPDATE cake_batches SET status = ? WHERE batch_id = ?', [status, batchId]);
  }

  // Insert audit record
  static async insertAuditRecord(audit: Omit<AuditRecord, 'audited_at'>): Promise<void> {
    const db = getDatabase();
    await db.run(
      `INSERT INTO audit_records (batch_id, auditor, audited_at, report_hash, comments, verdict)
       VALUES (?, ?, datetime('now'), ?, ?, ?)`,
      [audit.batch_id, audit.auditor, audit.report_hash, audit.comments, audit.verdict]
    );
  }

  // Get audit record
  static async getAuditRecord(batchId: number): Promise<AuditRecord | null> {
    const db = getDatabase();
    const result = await db.get('SELECT * FROM audit_records WHERE batch_id = ?', [batchId]);
    return result || null;
  }

  // Get all batches
  static async getAllBatches(): Promise<CakeBatch[]> {
    const db = getDatabase();
    return await db.all('SELECT * FROM cake_batches ORDER BY created_at DESC');
  }

  // Log sensor data anomaly
  static async logOracleAlert(batchId: number, alertType: string, message: string): Promise<void> {
    const db = getDatabase();
    await db.run(
      `INSERT INTO oracle_alerts (batch_id, alert_type, message, created_at)
       VALUES (?, ?, ?, datetime('now'))`,
      [batchId, alertType, message]
    );
  }

  // Clear all data from all tables (for reset/testing purposes)
  static async clearAllData(): Promise<void> {
    const db = getDatabase();
    
    // List of all tables to clear
    const tables = [
      'audit_records',
      'cake_batches', 
      'handoffs',
      'oracle_alerts',
      'quality_checks',
      'shipping_accidents',
      'status_logs'
    ];

    // Clear each table
    for (const table of tables) {
      await db.run(`DELETE FROM ${table}`);
      console.log(`Cleared table: ${table}`);
    }

    // Reset auto-increment counters if any exist
    await db.run(`DELETE FROM sqlite_sequence`);
    
    console.log('All database data cleared - database reset to brand new state');
  }
}
