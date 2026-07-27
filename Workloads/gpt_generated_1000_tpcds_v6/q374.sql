WITH
    filtered_ship AS (
        SELECT DISTINCT
            sm_ship_mode_sk,
            sm_ship_mode_id,
            sm_carrier
        FROM ship_mode
        WHERE sm_carrier LIKE '%Express%'
          AND regexp_like(sm_ship_mode_id, '^AAAAAAA[AB]A')
    ),
    overall AS (
        SELECT AVG(cr_return_amount) AS overall_avg
        FROM catalog_returns
    ),
    base AS (
        SELECT
            sm.sm_ship_mode_id,
            sm.sm_carrier,
            td.t_time_id,
            COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
            SUM(cr.cr_return_amount) AS total_return_amount,
            AVG(cr.cr_return_tax) AS avg_return_tax,
            AVG(cr.cr_return_amount) AS avg_return_amount
        FROM catalog_returns cr
        JOIN filtered_ship sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        WHERE td.t_minute BETWEEN 0 AND 5
          AND td.t_time_id LIKE 'AAAAAAA%AA%'
          AND regexp_like(td.t_time_id, 'A{8}A')
        GROUP BY
            sm.sm_ship_mode_id,
            sm.sm_carrier,
            td.t_time_id
    )
SELECT
    b.sm_ship_mode_id,
    b.sm_carrier,
    CONCAT(b.sm_ship_mode_id, '-', b.sm_carrier) AS ship_mode_desc,
    b.distinct_orders,
    b.total_return_amount,
    b.avg_return_tax,
    regexp_extract(b.t_time_id, '^(.....)', 1) AS time_id_prefix,
    CASE WHEN b.avg_return_amount > o.overall_avg THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS amount_vs_overall
FROM base b
CROSS JOIN overall o
ORDER BY b.total_return_amount DESC
LIMIT 100
