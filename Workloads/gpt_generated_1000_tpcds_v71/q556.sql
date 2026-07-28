WITH sales_agg AS (
   SELECT
     i.i_item_sk,
     i.i_item_id,
     i.i_product_name,
     'sales' AS metric_type,
     SUM(ws.ws_ext_sales_price) AS metric_value,
     SUM(ws.ws_quantity) AS metric_qty
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE p.p_discount_active = 'Y'
     AND wp.wp_autogen_flag = 'N'
     AND wp.wp_image_count >= 5
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
returns_agg AS (
   SELECT
     i.i_item_sk,
     i.i_item_id,
     i.i_product_name,
     'return' AS metric_type,
     SUM(wr.wr_return_amt) AS metric_value,
     SUM(wr.wr_return_quantity) AS metric_qty
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_autogen_flag = 'Y'
     AND wp.wp_image_count < 5
   GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
)

SELECT DISTINCT
  sa.i_item_id,
  sa.i_product_name,
  sa.metric_type,
  sa.metric_value,
  sa.metric_qty,
  (SELECT AVG(ws2.ws_sales_price)
     FROM web_sales ws2
     WHERE ws2.ws_item_sk = sa.i_item_sk) AS avg_sales_price
FROM sales_agg sa
WHERE sa.metric_value > 1000

UNION ALL

SELECT DISTINCT
  ra.i_item_id,
  ra.i_product_name,
  ra.metric_type,
  ra.metric_value,
  ra.metric_qty,
  (SELECT AVG(ws2.ws_sales_price)
     FROM web_sales ws2
     WHERE ws2.ws_item_sk = ra.i_item_sk) AS avg_sales_price
FROM returns_agg ra
WHERE NOT EXISTS (
   SELECT 1
   FROM promotion p2
   WHERE p2.p_item_sk = ra.i_item_sk
     AND p2.p_discount_active = 'Y'
)

ORDER BY metric_value DESC
LIMIT 100
