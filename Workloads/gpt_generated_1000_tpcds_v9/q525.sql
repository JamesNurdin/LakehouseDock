WITH high_value_customers AS (
   SELECT cd_demo_sk
   FROM customer_demographics
   WHERE cd_purchase_estimate > 5000
),
sales_union AS (
   SELECT
      i.i_category AS category,
      'catalog' AS sale_channel,
      cs.cs_net_profit AS net_profit,
      i.i_item_sk AS item_sk
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN high_value_customers hvc ON cs.cs_bill_cdemo_sk = hvc.cd_demo_sk
   WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_item_sk = i.i_item_sk
   )
   UNION ALL
   SELECT
      i.i_category AS category,
      'web' AS sale_channel,
      ws.ws_net_profit AS net_profit,
      i.i_item_sk AS item_sk
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN high_value_customers hvc ON ws.ws_bill_cdemo_sk = hvc.cd_demo_sk
   WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_item_sk = i.i_item_sk
   )
)
SELECT
   category,
   sale_channel,
   SUM(net_profit) AS total_net_profit,
   COUNT(DISTINCT item_sk) AS distinct_items
FROM sales_union
WHERE category IN (
   SELECT i_category
   FROM item
   WHERE i_wholesale_cost > 5
)
GROUP BY category, sale_channel
HAVING SUM(net_profit) > 1000
ORDER BY total_net_profit DESC
