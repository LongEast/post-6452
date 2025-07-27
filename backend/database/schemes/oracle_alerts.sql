CREATE TABLE oracle_alerts (
    batch_id     BIGINT REFERENCES cake_batches(batch_id) ON DELETE CASCADE,
    timestamp    TIMESTAMP NOT NULL,
    alert_count  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (batch_id, timestamp)
);