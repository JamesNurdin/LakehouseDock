WITH active_promotions AS (
   SELECT p.p_promo_sk, p.p_promo_name, p.p_item_sk, p.p_cost
   FROM promotion p
   WHERE p.p_discount_active = 'Y'
     AND p.p_cost > 500
),
store_agg AS (
   SELECT
     i.i_item_id,
     i.i_product_name,
     'Store' AS channel,
     SUM(ss.ss_ext_sales_price) AS total_sales,
     SUM(ss.ss_quantity) AS total_quantity
   FROM store_sales ss
   JOIN active_promotions ap ON ss.ss_promo_sk = ap.p_promo_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk AND ap.p_item_sk = i.i_item_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE ca.ca_gmt_offset = -5.00
     AND td.t_hour BETWEEN 9 AND 17
   GROUP BY i.i_item_id, i.i_product_name
),
web_agg AS (
   SELECT
     i.i_item_id,
     i.i_product_name,
     'Web' AS channel,
     SUM(ws.ws_ext_sales_price) AS total_sales,
     SUM(ws.ws_quantity) AS total_quantity
   FROM web_sales ws
   JOIN active_promotions ap ON ws.ws_promo_sk = ap.p_promo_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk AND ap.p_item_sk = i.i_item_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE ca.ca_gmt_offset = -5.00
     AND td.t_hour BETWEEN 9 AND 17
   GROUP BY i.i_item_id, i.i_product_name
)
SELECT
  channel,
  i_item_id,
  i_product_name,
  total_sales,
  total_quantity,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS sales_rank
FROM (
   SELECT i_item_id, i_product_name, channel, total_sales, total_quantity FROM store_agg
   UNION ALL
   SELECT i_item_id, i_product_name, channel, total_sales, total_quantity FROM web_agg
) combined
ORDER BY channel, sales_rank
LIMIT 100
