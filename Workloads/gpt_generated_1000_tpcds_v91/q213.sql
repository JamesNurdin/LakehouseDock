WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        cr.cr_returned_time_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
),
base AS (
    SELECT
        sr.cs_order_number,
        sr.cs_sold_date_sk,
        COALESCE(sr.cs_sold_time_sk, sr.cr_returned_time_sk) AS time_sk,
        COALESCE(sr.cs_ship_mode_sk, sr.cr_ship_mode_sk) AS ship_mode_sk,
        COALESCE(sr.cs_warehouse_sk, sr.cr_warehouse_sk) AS warehouse_sk,
        sr.cs_net_profit,
        sr.cs_quantity,
        sr.cs_item_sk,
        sr.cr_return_amount,
        sr.cr_return_quantity,
        sr.cr_reason_sk
    FROM sales_returns sr
),
filtered AS (
    SELECT
        b.*,
        r.r_reason_desc,
        r.r_reason_id,
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_carrier,
        t.t_hour,
        t.t_am_pm,
        CONCAT('ORD', CAST(b.cs_order_number AS VARCHAR)) AS order_key
    FROM base b
    LEFT JOIN reason r
        ON b.cr_reason_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm
        ON b.ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN time_dim t
        ON b.time_sk = t.t_time_sk
    WHERE (b.cr_reason_sk IS NOT NULL AND regexp_like(r.r_reason_desc, '(?i)time'))
          OR (sm.sm_type IS NOT NULL AND sm.sm_type LIKE '%Air%')
)
SELECT
    f.sm_ship_mode_id,
    f.sm_type,
    f.sm_carrier,
    COUNT(DISTINCT f.cs_order_number) AS distinct_orders,
    SUM(COALESCE(f.cs_net_profit, 0) - COALESCE(f.cr_return_amount, 0)) AS net_revenue,
    AVG(COALESCE(f.cs_net_profit, 0)) AS avg_net_profit,
    MAX(f.t_hour) AS latest_hour,
    array_join(array_agg(DISTINCT f.r_reason_desc), '; ') AS distinct_return_reasons,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_mode_sk = f.ship_mode_sk
    ) AS overall_avg_net_profit
FROM filtered f
WHERE f.sm_type IS NOT NULL
GROUP BY f.sm_ship_mode_id, f.sm_type, f.sm_carrier, f.ship_mode_sk
HAVING COUNT(DISTINCT f.cs_order_number) > 5
ORDER BY net_revenue DESC
LIMIT 100
