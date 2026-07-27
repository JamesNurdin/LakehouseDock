WITH ws AS (
   SELECT
       ws_item_sk,
       ws_warehouse_sk,
       ws_order_number,
       SUM(ws_net_profit) AS web_sales_profit,
       SUM(ws_quantity) AS web_qty,
       ws_sold_time_sk
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_shift = 'first'
   GROUP BY ws_item_sk, ws_warehouse_sk, ws_order_number, ws_sold_time_sk
),
ss AS (
   SELECT
       ss_item_sk,
       SUM(ss_net_paid) AS store_sales_paid,
       SUM(ss_quantity) AS store_qty,
       ss_sold_time_sk
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE td.t_shift = 'first'
   GROUP BY ss_item_sk, ss_sold_time_sk
),
cr AS (
   SELECT
       cr_item_sk,
       cr_warehouse_sk,
       SUM(cr_net_loss) AS catalog_return_loss,
       cr_returned_time_sk
   FROM catalog_returns cr
   JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
   WHERE td.t_shift = 'first'
   GROUP BY cr_item_sk, cr_warehouse_sk, cr_returned_time_sk
),
wr AS (
   SELECT
       wr_item_sk,
       wr_order_number,
       SUM(wr_net_loss) AS web_return_loss,
       wr_returned_time_sk
   FROM web_returns wr
   JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
   WHERE td.t_shift = 'first'
   GROUP BY wr_item_sk, wr_order_number, wr_returned_time_sk
)
SELECT
   i.i_item_id,
   i.i_product_name,
   w.w_warehouse_name,
   ws.web_sales_profit,
   ss.store_sales_paid,
   cr.catalog_return_loss,
   wr.web_return_loss,
   (ws.web_sales_profit + ss.store_sales_paid - cr.catalog_return_loss - wr.web_return_loss) AS total_net,
   CASE WHEN (ws.web_sales_profit + ss.store_sales_paid) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_indicator,
   ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY (ws.web_sales_profit + ss.store_sales_paid - cr.catalog_return_loss - wr.web_return_loss) DESC) AS warehouse_rank
FROM ws
JOIN ss ON ws.ws_item_sk = ss.ss_item_sk
JOIN cr ON ws.ws_item_sk = cr.cr_item_sk AND ws.ws_warehouse_sk = cr.cr_warehouse_sk
JOIN wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1 FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
      AND inv.inv_quantity_on_hand > 100
)
  AND w.w_country = 'United States'
  AND i.i_brand = 'Brand#1'
  AND i.i_category = 'Electronics'
  AND w.w_county = 'Walker County'
LIMIT 100
