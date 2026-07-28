WITH sales_returns AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        sm.sm_type,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT OUTER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001                                 -- predicate 1
      AND sm.sm_type IN ('AIR', 'GROUND')                -- predicate 2
      AND r.r_reason_desc LIKE '%service%'               -- predicate 3
      AND cs.cs_net_paid BETWEEN 1000 AND 50000          -- predicate 4
      AND cr.cr_return_amount > 10                       -- predicate 5
      AND cs.cs_quantity > 0                             -- predicate 6
    GROUP BY r.r_reason_sk, r.r_reason_desc, sm.sm_type, d.d_year
)
SELECT DISTINCT
    sr.r_reason_desc,
    sr.sm_type,
    sr.d_year,
    sr.total_net_paid,
    sr.total_return_amount,
    sr.distinct_orders,
    sr.total_quantity,
    (sr.total_return_amount / NULLIF(sr.total_quantity, 0)) AS avg_return_per_qty
FROM sales_returns sr
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    WHERE wr.wr_reason_sk = sr.r_reason_sk
      AND d2.d_year = sr.d_year
)
GROUP BY
    sr.r_reason_desc,
    sr.sm_type,
    sr.d_year,
    sr.total_net_paid,
    sr.total_return_amount,
    sr.distinct_orders,
    sr.total_quantity
HAVING sr.total_return_amount > 5000
ORDER BY sr.total_return_amount DESC
LIMIT 100
