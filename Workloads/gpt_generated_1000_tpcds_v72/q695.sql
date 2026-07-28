WITH cs_agg AS (
   SELECT cs_item_sk,
          cs_warehouse_sk,
          MIN(cs_call_center_sk) AS cs_call_center_sk,
          SUM(cs_net_paid) AS total_net_paid,
          SUM(cs_quantity) AS total_quantity,
          SUM(cs_net_profit) AS total_net_profit
   FROM catalog_sales
   WHERE cs_quantity > 0
   GROUP BY cs_item_sk, cs_warehouse_sk
),
cr_agg AS (
   SELECT cr_item_sk,
          SUM(cr_return_amount) AS total_catalog_return_amount,
          SUM(cr_return_quantity) AS total_catalog_return_qty
   FROM catalog_returns
   WHERE cr_return_amount > 0
   GROUP BY cr_item_sk
),
sr_agg AS (
   SELECT sr_item_sk,
          SUM(sr_return_amt) AS total_store_return_amt,
          SUM(sr_return_quantity) AS total_store_return_qty
   FROM store_returns
   WHERE sr_return_amt > 0
   GROUP BY sr_item_sk
),
wr_agg AS (
   SELECT wr_item_sk,
          SUM(wr_return_amt) AS total_web_return_amt,
          SUM(wr_return_quantity) AS total_web_return_qty
   FROM web_returns
   WHERE wr_return_amt > 0
   GROUP BY wr_item_sk
)
SELECT
   i.i_item_id,
   i.i_product_name,
   i.i_color,
   i.i_size,
   w.w_warehouse_name,
   cc.cc_name,
   cs_agg.total_quantity,
   cs_agg.total_net_paid,
   cs_agg.total_net_profit,
   COALESCE(cr_agg.total_catalog_return_amount, 0) AS total_catalog_return_amount,
   COALESCE(sr_agg.total_store_return_amt, 0) AS total_store_return_amt,
   COALESCE(wr_agg.total_web_return_amt, 0) AS total_web_return_amt,
   inventory.inv_quantity_on_hand,
   cs_agg.total_net_paid
     - COALESCE(cr_agg.total_catalog_return_amount, 0)
     - COALESCE(sr_agg.total_store_return_amt, 0)
     - COALESCE(wr_agg.total_web_return_amt, 0) AS net_contribution,
   CASE
       WHEN cs_agg.total_net_profit > 20000 THEN 'HIGH'
       WHEN cs_agg.total_net_profit > 5000  THEN 'MEDIUM'
       ELSE 'LOW'
   END AS profit_category,
   ROW_NUMBER() OVER (
       PARTITION BY w.w_warehouse_sk
       ORDER BY cs_agg.total_net_profit DESC
   ) AS profit_rank_within_warehouse
FROM cs_agg
JOIN item i ON cs_agg.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN cr_agg ON cr_agg.cr_item_sk = i.i_item_sk
LEFT JOIN sr_agg ON sr_agg.sr_item_sk = i.i_item_sk
LEFT JOIN wr_agg ON wr_agg.wr_item_sk = i.i_item_sk
JOIN inventory ON inventory.inv_item_sk = i.i_item_sk
               AND inventory.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_color IN ('rosy', 'purple')
  AND cc.cc_name LIKE '%Center%'
  AND inventory.inv_quantity_on_hand > 0
ORDER BY net_contribution DESC
LIMIT 100
