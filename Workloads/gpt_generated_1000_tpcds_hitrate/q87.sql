WITH sales_agg AS (
    SELECT
        cs_warehouse_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_sales_price) AS avg_price,
        COUNT(*) AS order_count,
        MIN(cs_sales_price) AS min_price,
        MAX(cs_sales_price) AS max_price
    FROM catalog_sales
    WHERE cs_sales_price > 20
      AND cs_quantity BETWEEN 1 AND 10
      AND cs_ship_hdemo_sk IN (1756, 2319, 6203)
      AND cs_wholesale_cost < 50
      AND cs_net_paid_inc_ship > 500
    GROUP BY cs_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    w.w_city,
    s.total_sales,
    s.avg_price,
    s.order_count,
    s.min_price,
    s.max_price
FROM sales_agg s
JOIN (
    SELECT *
    FROM warehouse
    TABLESAMPLE BERNOULLI (20)
) w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
WHERE w.w_warehouse_sq_ft > 300000
  AND w.w_suite_number LIKE 'Suite %'
  AND w.w_state = 'CA'
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    w.w_city,
    s.total_sales,
    s.avg_price,
    s.order_count,
    s.min_price,
    s.max_price
HAVING s.total_sales > 10000
ORDER BY s.total_sales DESC
LIMIT 100
