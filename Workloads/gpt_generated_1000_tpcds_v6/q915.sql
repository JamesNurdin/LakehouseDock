WITH filtered_sales AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_wholesale_cost,
        ss.ss_ext_wholesale_cost,
        ss.ss_net_paid_inc_tax,
        ss.ss_quantity,
        ss.ss_item_sk,
        ss.ss_store_sk
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost > 50
      AND ss.ss_ext_wholesale_cost BETWEEN 1000 AND 3000
      AND ss.ss_quantity >= 1
)
SELECT
    cc.cc_name,
    td.t_hour,
    td.t_minute,
    COUNT(DISTINCT fs.ss_item_sk) AS distinct_items_sold,
    SUM(fs.ss_ext_wholesale_cost) AS total_wholesale_cost,
    AVG(cs.cs_ext_sales_price) AS avg_catalog_sales_price,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_positive_profit,
    MAX(td.t_second) AS max_second
FROM filtered_sales fs
JOIN time_dim td
    ON fs.ss_sold_time_sk = td.t_time_sk
JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE td.t_second IN (7, 15)
  AND td.t_minute >= 2
  AND cs.cs_ship_customer_sk IN (4706359, 4098294)
  AND cs.cs_ext_wholesale_cost > 500
  AND cc.cc_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = cs.cs_order_number
          AND cs2.cs_quantity > 5
    )
GROUP BY cc.cc_name, td.t_hour, td.t_minute
ORDER BY total_wholesale_cost DESC
LIMIT 100
