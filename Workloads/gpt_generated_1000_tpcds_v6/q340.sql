WITH sales_by_hour AS (
    SELECT
        td.t_hour AS hour,
        'sales' AS metric_type,
        SUM(cs.cs_ext_sales_price) AS total_amount
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 0
      AND p.p_discount_active = 'Y'
      AND td.t_second = 0
    GROUP BY td.t_hour
),
returns_by_hour AS (
    SELECT
        td.t_hour AS hour,
        'returns' AS metric_type,
        SUM(wr.wr_return_amt) AS total_amount
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wr.wr_return_quantity > 0
      AND td.t_second = 0
    GROUP BY td.t_hour
)
SELECT hour, metric_type, total_amount
FROM sales_by_hour
UNION ALL
SELECT hour, metric_type, total_amount
FROM returns_by_hour
ORDER BY hour, metric_type
LIMIT 100
