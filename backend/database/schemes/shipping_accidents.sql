CREATE TABLE shipping_accidents (
    id         SERIAL PRIMARY KEY,
    batch_id   BIGINT REFERENCES cake_batches(batch_id) ON DELETE CASCADE,
    timestamp  TIMESTAMP NOT NULL,
    actor      TEXT NOT NULL,
    accident   TEXT NOT NULL
);