/*
  Goal: Calculate per‑warehouse total sales and profit for a subset of customers
  (cs_bill_hdemo_sk), only for high shipping‑cost transactions and a specific
  warehouse suite. Then aggregate those results to obtain the overall average
  profit per warehouse, total sales across all qualifying warehouses, and the
  count of such warehouses, keeping only warehouses with substantial sales.
*/
WITH warehouse_sales AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_bill_hdemo_sk IN (5567, 6622, 1573)
      AND cs.cs_ext_ship_cost > 500
      AND w.w_suite_number = 'Suite 90'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    AVG(total_profit) AS avg_profit_per_warehouse,
    SUM(total_sales) AS grand_total_sales,
    COUNT(*) AS warehouse_cnt
FROM warehouse_sales
WHERE total_sales > 20000
HAVING AVG(total_profit) > 5000
LIMIT 100
