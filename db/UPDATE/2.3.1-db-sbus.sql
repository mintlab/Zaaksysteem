-- sbus_type StUF / CSV / ETC
-- object: PRS, 
-- input: e.g. XML
-- output: e.g. XML
-- mutatie_type T V W C

CREATE TABLE sbus_traffic (
    id              SERIAL PRIMARY KEY,
    sbus_type       TEXT,
    object          TEXT,
    operation       TEXT,
    input           TEXT,
    input_raw       TEXT,
    output          TEXT,
    output_raw      TEXT,
    error           BOOLEAN,
    error_message   TEXT,
    created         timestamp without time zone,
    modified        timestamp without time zone
);

CREATE TABLE sbus_logging (
    id              SERIAL PRIMARY KEY,
    sbus_traffic_id INTEGER REFERENCES sbus_traffic(id),
    pid             INTEGER REFERENCES sbus_logging(id),
    mutatie_type    TEXT,
    object          TEXT,
    params          TEXT,
    kerngegeven     TEXT,
    label           TEXT,
    changes         TEXT,
    error           BOOLEAN,
    error_message   TEXT,
    created         timestamp without time zone,
    modified        timestamp without time zone
);
