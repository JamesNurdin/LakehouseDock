SELECT
    w.w_warehouse_name,
    w.w_city,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(*) AS sales_count
FROM tpcds.catalog_sales cs
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_ext_wholesale_cost > 1000
  AND w.w_warehouse_sq_ft > 600000
  AND cs.cs_warehouse_sk IN (8, 9)
GROUP BY w.w_warehouse_name, w.w_city
ORDER BY total_net_paid DESC
LIMIT 100
