CREATE TABLE if not exists cake_batches (
    batch_id       BIGINT PRIMARY KEY,
    created_at     TIMESTAMP NOT NULL,
    baker_address  TEXT NOT NULL,
    metadata_uri   TEXT,
    min_temp       FLOAT,
    max_temp       FLOAT,
    min_humidity   FLOAT,
    max_humidity   FLOAT,
    is_flagged     BOOLEAN DEFAULT FALSE,
    status         TEXT NOT NULL CHECK (status IN (
        'Created', 'HandedToShipper', 'ArrivedWarehouse', 'Delivered', 'Spoiled', 'Audited'
    ))
);