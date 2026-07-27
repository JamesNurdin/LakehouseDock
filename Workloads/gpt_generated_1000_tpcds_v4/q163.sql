WITH sales_by_ship AS (
    SELECT sm.sm_type AS category,
           SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY sm.sm_type
),
returns_by_reason AS (
    SELECT r.r_reason_desc AS category,
           SUM(cr.cr_return_amount) AS total_sales
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY r.r_reason_desc
),
combined AS (
    SELECT category, total_sales FROM sales_by_ship
    UNION ALL
    SELECT category, total_sales FROM returns_by_reason
)
SELECT c.category,
       c.total_sales,
       c.total_sales / (
           SELECT SUM(cs.cs_ext_sales_price)
           FROM catalog_sales cs
           JOIN time_dim t2 ON cs.cs_sold_time_sk = t2.t_time_sk
           WHERE t2.t_hour BETWEEN 9 AND 17
       ) * 100.0 AS pct_of_total_sales
FROM combined c
ORDER BY c.total_sales DESC
LIMIT 100
