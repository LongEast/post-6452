CREATE TABLE quality_checks (
    id             SERIAL PRIMARY KEY,
    batch_id       BIGINT REFERENCES cake_batches(batch_id) ON DELETE CASCADE,
    snapshot_hash  TEXT NOT NULL,
    by             TEXT NOT NULL CHECK (by IN ('baker', 'warehouse')),
    timestamp      TIMESTAMP NOT NULL,
    is_random      BOOLEAN NOT NULL DEFAULT FALSE
);