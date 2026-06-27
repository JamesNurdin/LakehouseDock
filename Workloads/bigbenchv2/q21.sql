WITH logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 1), '') AS bigint)   AS wl_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint)   AS wl_customer_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint)   AS wl_item_id,
        NULLIF(element_at(split(line, '|'), 4), '')                       AS wl_webpage_name,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_ts
    FROM iceberg.bigbenchv2_sf1.web_logs
),

filtered AS (
    SELECT
        wl_customer_id,
        wl_webpage_name,
        wl_ts,
        CASE WHEN wl_webpage_name IN (
                'webpage#21','webpage#22','webpage#23','webpage#24','webpage#25'
             ) THEN 1 ELSE 0 END                                            AS is_purchase,
        -- Number of purchases that have occurred *before* the current row
        COALESCE(
            SUM(CASE WHEN wl_webpage_name IN (
                    'webpage#21','webpage#22','webpage#23','webpage#24','webpage#25'
                 ) THEN 1 ELSE 0 END)
                OVER (PARTITION BY wl_customer_id
                      ORDER BY wl_ts
                      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),
            0)                                                               AS prior_purchases
    FROM logs
    WHERE wl_customer_id IS NOT NULL
),

with_path AS (
    SELECT *, prior_purchases + 1 AS path_id
    FROM filtered
),

purchase_rows AS (
    SELECT wl_customer_id, wl_ts, path_id
    FROM with_path
    WHERE is_purchase = 1
),

paths AS (
    SELECT
        p.wl_customer_id,
        p.path_id,
        array_join(
            array_agg(w.wl_webpage_name ORDER BY w.wl_ts),
            ' -> '
        ) AS path_to_purchase
    FROM purchase_rows p
    JOIN with_path w
      ON w.wl_customer_id = p.wl_customer_id
     AND w.path_id = p.path_id
    GROUP BY p.wl_customer_id, p.path_id
)

SELECT
    path_to_purchase,
    COUNT(*) AS freq
FROM paths
GROUP BY path_to_purchase
ORDER BY freq DESC
LIMIT 5