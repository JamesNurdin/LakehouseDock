WITH cs_filtered AS (
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_net_paid_inc_tax,
        cs_net_profit,
        cs_ship_customer_sk,
        cs_order_number
    FROM catalog_sales
    WHERE cs_net_paid_inc_tax > 3000
      AND cs_ship_customer_sk IN (
          SELECT ss_customer_sk FROM store_sales WHERE ss_sales_price > 80
      )
      AND cs_item_sk IN (
          SELECT ss_item_sk FROM store_sales WHERE ss_sales_price > 80
      )
),
key_diff AS (
    SELECT cs_ship_customer_sk FROM cs_filtered
    EXCEPT
    SELECT ss_customer_sk FROM store_sales
)
SELECT
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(ss.ss_sales_price) AS avg_store_sales_price,
    MAX(cs.cs_net_profit) AS max_net_profit
FROM cs_filtered cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND ss.ss_sales_price < 90
  AND cs.cs_ship_customer_sk IN (SELECT cs_ship_customer_sk FROM key_diff)
GROUP BY d.d_year, d.d_month_seq
HAVING COUNT(*) > 50
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
