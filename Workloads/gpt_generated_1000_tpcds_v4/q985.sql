/* goal: Identify warehouses with above‑average net profit after filtering for high discount amounts, moderate total paid amounts, and reasonable GMT offset, and show each warehouse's sales summary together with the overall average sales */
WITH warehouse_sales AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_county,
        SUM(cs.cs_net_profit)          AS total_net_profit,
        SUM(cs.cs_ext_sales_price)     AS total_sales,
        COUNT(*)                       AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ext_discount_amt > 1000
      AND cs.cs_net_paid_inc_ship_tax BETWEEN 2000 AND 8000
      AND w.w_gmt_offset >= -5.00
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_county
)
SELECT
    ws.w_warehouse_name,
    ws.w_city,
    ws.w_county,
    ws.total_net_profit,
    ws.total_sales,
    ws.order_cnt,
    (SELECT AVG(total_sales) FROM warehouse_sales) AS avg_sales_all
FROM warehouse_sales ws
WHERE ws.total_net_profit > (SELECT AVG(total_net_profit) FROM warehouse_sales)
  AND EXISTS (
        SELECT 1
        FROM tpcds.warehouse w2
        WHERE w2.w_county = ws.w_county
          AND w2.w_gmt_offset > 0
      )
ORDER BY ws.total_net_profit DESC
LIMIT 100
