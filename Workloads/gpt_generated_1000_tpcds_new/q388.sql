WITH agg_returns AS (
    SELECT
        sr_store_sk,
        sr_return_time_sk,
        SUM(sr_return_amt)           AS total_return_amt,
        SUM(sr_return_tax)           AS total_return_tax,
        COUNT(*)                     AS cnt_returns
    FROM store_returns
    WHERE sr_return_tax            > 5.00
      AND sr_return_ship_cost      < 500.00
      AND sr_return_quantity       >= 1
      AND sr_return_amt            > 100.00
      AND sr_return_time_sk        IN (60645, 54713, 41617)
      AND sr_store_sk IN (
          SELECT s_store_sk
          FROM store
          WHERE s_floor_space > 8000000
      )
    GROUP BY sr_store_sk, sr_return_time_sk
),

time_filtered AS (
    SELECT *
    FROM time_dim
    WHERE t_sub_shift IN ('morning', 'afternoon')
      AND t_hour BETWEEN 8 AND 16
),

store_filtered AS (
    SELECT *
    FROM store
    WHERE s_floor_space      BETWEEN 5000000 AND 10000000
      AND s_city             = 'Park First'
      AND s_state            = 'CA'
      AND s_zip              = '35804'
      AND s_gmt_offset      >= -5.00
      AND s_tax_percentage  < 8.00
),

intersect_keys AS (
    SELECT sr_store_sk AS store_key FROM agg_returns
    INTERSECT
    SELECT s_store_sk FROM store_filtered
)
SELECT
    COALESCE(s.s_store_id, CAST(ar.sr_store_sk AS VARCHAR))            AS store_identifier,
    COALESCE(s.s_store_name, 'UNKNOWN')                               AS store_name,
    t.t_sub_shift,
    ar.total_return_amt,
    ar.total_return_tax,
    ar.cnt_returns,
    CASE
        WHEN ar.total_return_amt > 10000 THEN 'HIGH'
        WHEN ar.total_return_amt >  5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END                                                               AS return_level,
    lt.max_hour_in_shift
FROM store_filtered s
FULL OUTER JOIN agg_returns ar
    ON s.s_store_sk = ar.sr_store_sk
RIGHT OUTER JOIN time_filtered t
    ON ar.sr_return_time_sk = t.t_time_sk
LEFT JOIN LATERAL (
    SELECT MAX(t2.t_hour) AS max_hour_in_shift
    FROM time_dim t2
    WHERE t2.t_time_sk = ar.sr_return_time_sk
) lt ON TRUE
WHERE s.s_store_sk IN (SELECT store_key FROM intersect_keys)
  AND (s.s_state = 'CA' OR s.s_state IS NULL)
  AND (t.t_sub_shift = 'morning' OR t.t_sub_shift = 'afternoon')
  AND ar.cnt_returns > 0
  AND ar.total_return_tax > 5.00
ORDER BY ar.total_return_amt DESC NULLS LAST
LIMIT 100
