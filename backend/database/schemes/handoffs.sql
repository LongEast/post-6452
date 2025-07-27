CREATE TABLE handoffs (
    id             SERIAL PRIMARY KEY,
    batch_id       BIGINT REFERENCES cake_batches(batch_id) ON DELETE CASCADE,
    from_actor     TEXT NOT NULL,
    to_actor       TEXT NOT NULL,
    longitude      NUMERIC(9,6),
    latitude       NUMERIC(9,6),
    snapshot_hash  TEXT,
    timestamp      TIMESTAMP NOT NULL
);