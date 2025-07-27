CREATE TABLE status_logs (
    id         SERIAL PRIMARY KEY,
    batch_id   BIGINT REFERENCES cake_batches(batch_id) ON DELETE CASCADE,
    status     TEXT NOT NULL,
    details    TEXT,
    timestamp  TIMESTAMP NOT NULL
);