-- Trigger & Audit Table: Track status changes
CREATE TABLE IF NOT EXISTS system_audit_log (
    id SERIAL PRIMARY KEY,
    table_name TEXT,
    record_id TEXT,
    old_value TEXT,
    new_value TEXT,
    changed_by TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- A. JSONB Usage
ALTER TABLE survey ADD COLUMN IF NOT EXISTS metadata JSONB;
SELECT title FROM survey WHERE metadata->>'theme' = 'dark';

-- B. Table Partitioning
CREATE TABLE response_answer_partitioned (
    id SERIAL,
    textValue TEXT,
    createdAt TIMESTAMP,
    responseId INT,
    questionId INT
) PARTITION BY RANGE (createdAt);

CREATE TABLE response_answer_2024 PARTITION OF response_answer_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE response_answer_2025 PARTITION OF response_answer_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
