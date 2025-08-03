CREATE TABLE oracle_alerts (
    batch_id     BIGINT REFERENCES cake_batches(batch_id) ON DELETE CASCADE,
    timestamp    TIMESTAMP,
    alert_count  INTEGER NOT NULL DEFAULT 0,
    alert_type    TEXT       NOT NULL DEFAULT 'SENSOR_ALERT',
    message TEXT       NOT NULL DEFAULT '',
    created_at    TIMESTAMP  NOT NULL,  

    PRIMARY KEY (batch_id, timestamp)
);
