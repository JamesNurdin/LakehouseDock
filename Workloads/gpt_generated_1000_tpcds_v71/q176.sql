WITH
store_agg AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       p.p_promo_name,
       SUM(ss.ss_ext_sales_price) AS sales_amount,
       SUM(ss.ss_net_profit) AS profit,
       COUNT(*) AS txn_cnt,
       'store' AS channel
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_wholesale_cost > 20
     AND ss.ss_promo_sk = 106
   GROUP BY i.i_item_id, i.i_product_name, p.p_promo_name
),
web_agg AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       p.p_promo_name,
       SUM(ws.ws_ext_sales_price) AS sales_amount,
       SUM(ws.ws_net_profit) AS profit,
       COUNT(*) AS txn_cnt,
       'web' AS channel
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE ws.ws_net_paid_inc_ship > 1000
     AND p.p_promo_id LIKE 'PROMO%'
   GROUP BY i.i_item_id, i.i_product_name, p.p_promo_name
),
combined_sales AS (
   SELECT * FROM store_agg
   UNION ALL
   SELECT * FROM web_agg
),
sales_summary AS (
   SELECT
       i_item_id,
       i_product_name,
       p_promo_name,
       SUM(sales_amount) AS total_sales_amount,
       SUM(profit) AS total_profit,
       SUM(txn_cnt) AS total_txn_cnt,
       COUNT(DISTINCT channel) AS channel_count,
       CASE WHEN SUM(sales_amount) > 15000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category
   FROM combined_sales
   GROUP BY i_item_id, i_product_name, p_promo_name
),
catalog_ret AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       SUM(cr.cr_return_amount) AS catalog_return_amount,
       COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE cr.cr_return_quantity > 1
     AND cr.cr_return_amount > 50
   GROUP BY i.i_item_id, i.i_product_name
),
web_ret AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       SUM(wr.wr_return_amt) AS web_return_amount,
       COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE wr.wr_return_quantity > 1
     AND wr.wr_return_amt > 30
   GROUP BY i.i_item_id, i.i_product_name
),
returns_summary AS (
   SELECT
       c.i_item_id,
       c.i_product_name,
       c.catalog_return_amount,
       c.catalog_return_cnt,
       COALESCE(w.web_return_amount, 0) AS web_return_amount,
       COALESCE(w.web_return_cnt, 0) AS web_return_cnt
   FROM catalog_ret c
   LEFT JOIN web_ret w
     ON c.i_item_id = w.i_item_id
    AND c.i_product_name = w.i_product_name
)
SELECT DISTINCT
   ss.i_item_id,
   ss.i_product_name,
   ss.p_promo_name,
   ss.total_sales_amount,
   ss.total_profit,
   ss.total_txn_cnt,
   ss.channel_count,
   ss.sales_category,
   rs.catalog_return_amount,
   rs.catalog_return_cnt,
   rs.web_return_amount,
   rs.web_return_cnt,
   CASE
       WHEN ss.total_sales_amount - rs.catalog_return_amount - rs.web_return_amount > 0 THEN 'POSITIVE'
       ELSE 'NON-POSITIVE'
   END AS net_sales_indicator
FROM sales_summary ss
LEFT JOIN returns_summary rs
  ON ss.i_item_id = rs.i_item_id
 AND ss.i_product_name = rs.i_product_name
ORDER BY ss.total_sales_amount DESC
LIMIT 100
