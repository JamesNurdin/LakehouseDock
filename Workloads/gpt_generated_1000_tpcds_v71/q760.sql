WITH promoted_items AS (
   SELECT p.p_item_sk
   FROM promotion p
   WHERE p.p_channel_tv = 'Y'
),
store_sales_agg AS (
   SELECT
      i.i_item_id,
      i.i_product_name,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_quantity) AS total_qty,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE i.i_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2002-01-01'
     AND EXISTS (
         SELECT 1
         FROM promoted_items pi
         WHERE pi.p_item_sk = i.i_item_sk
     )
   GROUP BY i.i_item_id, i.i_product_name
),
web_sales_agg AS (
   SELECT
      i.i_item_id,
      i.i_product_name,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_quantity) AS total_qty,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE i.i_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2002-01-01'
     AND EXISTS (
         SELECT 1
         FROM promoted_items pi
         WHERE pi.p_item_sk = i.i_item_sk
     )
   GROUP BY i.i_item_id, i.i_product_name
)
SELECT
   combined.item_id,
   combined.product_name,
   combined.total_sales,
   combined.total_qty,
   combined.distinct_orders,
   RANK() OVER (ORDER BY combined.total_sales DESC) AS sales_rank
FROM (
   SELECT DISTINCT
      sa.i_item_id AS item_id,
      sa.i_product_name AS product_name,
      sa.total_sales,
      sa.total_qty,
      sa.distinct_orders
   FROM store_sales_agg sa
   UNION ALL
   SELECT DISTINCT
      wa.i_item_id AS item_id,
      wa.i_product_name AS product_name,
      wa.total_sales,
      wa.total_qty,
      wa.distinct_orders
   FROM web_sales_agg wa
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 100
