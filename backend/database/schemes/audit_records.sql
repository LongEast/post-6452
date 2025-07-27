CREATE TABLE audit_records (
    batch_id      BIGINT PRIMARY KEY REFERENCES cake_batches(batch_id) ON DELETE CASCADE,
    auditor       TEXT NOT NULL,
    audited_at    TIMESTAMP NOT NULL,
    report_hash   TEXT NOT NULL,
    comments      TEXT,
    verdict       TEXT NOT NULL CHECK (verdict IN ('PASS', 'FAIL', 'UNCLEAR'))
);