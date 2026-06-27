WITH logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 1), '') AS bigint)   AS wl_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint)   AS wl_customer_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint)   AS wl_item_id,
        NULLIF(element_at(split(line, '|'), 4), '')                       AS wl_webpage_name,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_timestamp,
        line
    FROM iceberg.bigbenchv2_sf1.web_logs
),

sessionize AS (
    SELECT
        wl_customer_id                                   AS uid,
        to_unixtime(wl_timestamp)                        AS tstamp,
        CASE
            WHEN (to_unixtime(wl_timestamp) -
                  lag(to_unixtime(wl_timestamp)) OVER (PARTITION BY wl_customer_id ORDER BY wl_timestamp))
                 >= 600
            THEN 1
            ELSE 0
        END                                            AS new_session
    FROM logs
    WHERE wl_customer_id IS NOT NULL
),

sessions AS (
    SELECT
        uid,
        tstamp,
        CONCAT(
            CAST(uid AS varchar),
            '_',
            CAST(SUM(new_session) OVER (PARTITION BY uid ORDER BY tstamp) AS varchar)
        ) AS session_id
    FROM sessionize
)

SELECT
    c.c_customer_id,
    c.c_name,
    COUNT(*) / 24.0 AS cnt
FROM sessions s
JOIN iceberg.bigbenchv2_sf1.customers c
  ON s.uid = c.c_customer_id
GROUP BY
    c.c_customer_id,
    c.c_name
ORDER BY cnt DESC
LIMIT 10
