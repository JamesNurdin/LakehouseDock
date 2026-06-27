/*
  BigBenchV2 Q23 – Top‑10 customers by number of web‑log visits
  Ported from HiveQL to Trino (Iceberg catalog).
  The original Hive query extracted the field *wl_customer_id* from a JSON
  string. In the Iceberg version the raw log line is pipe‑delimited, so we
  parse it with `split()` and cast the second element to BIGINT.
*/
WITH logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS wl_customer_id,
        line
    FROM iceberg.bigbenchv2_sf1.web_logs
    -- keep only rows where the id could be parsed – the WHERE clause in the
    -- outer query also guards against NULLs, but filtering early can reduce
    -- the amount of data shuffled.
    WHERE element_at(split(line, '|'), 2) IS NOT NULL
)
SELECT
    c.c_customer_id,
    c.c_name,
    COUNT(*) AS Visits
FROM logs l
JOIN iceberg.bigbenchv2_sf1.customers c
    ON l.wl_customer_id = c.c_customer_id
WHERE l.wl_customer_id IS NOT NULL
GROUP BY
    c.c_customer_id,
    c.c_name
ORDER BY Visits DESC
LIMIT 10