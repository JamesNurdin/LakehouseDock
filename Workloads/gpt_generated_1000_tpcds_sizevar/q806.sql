WITH
  sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  item_cr AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_brand,
      i.i_brand_id,
      i.i_category,
      i.i_color,
      cr.cr_return_quantity,
      cr.cr_return_amount
    FROM item i
    FULL OUTER JOIN catalog_returns cr
      ON i.i_item_sk = cr.cr_item_sk
  ),
  joined_data AS (
    SELECT
      ss.ws_order_number,
      ss.ws_item_sk,
      ss.ws_web_site_sk,
      ss.ws_ship_mode_sk,
      ss.ws_warehouse_sk,
      ss.ws_promo_sk,
      ss.ws_net_paid,
      ss.ws_net_paid_inc_tax,
      ss.ws_ship_date_sk,
      icr.i_item_id,
      icr.i_brand,
      icr.i_brand_id,
      icr.i_category,
      icr.i_color,
      icr.cr_return_quantity,
      icr.cr_return_amount,
      p.p_promo_name,
      p.p_discount_active,
      sm.sm_type,
      w.w_warehouse_name,
      w.w_state,
      wp.wp_type,
      ws.web_site_id
    FROM sampled_sales ss
    LEFT JOIN item_cr icr
      ON ss.ws_item_sk = icr.i_item_sk
    LEFT JOIN promotion p
      ON ss.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
      ON ss.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
      ON ss.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp
      ON ss.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws
      ON ss.ws_web_site_sk = ws.web_site_sk
  ),
  ranked AS (
    SELECT
      *,
      RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY ws_net_paid DESC) AS sales_rank
    FROM joined_data
    WHERE
      ws_ship_date_sk BETWEEN 2451458 AND 2452707
      AND i_brand_id IN (1, 2, 3)
      AND i_color = 'Red'
      AND sm_type = 'AIR'
      AND w_state = 'CA'
      AND wp_type = 'home'
      AND p_discount_active = 'Y'
  )
SELECT
  ws_order_number,
  i_item_id,
  i_brand,
  i_category,
  p_promo_name,
  sm_type,
  w_warehouse_name,
  ws_net_paid,
  ws_ship_date_sk,
  cr_return_quantity,
  cr_return_amount,
  wp_type,
  web_site_id,
  COUNT(DISTINCT ws_order_number) OVER (PARTITION BY i_brand) AS distinct_orders_per_brand,
  COUNT(DISTINCT i_category) OVER (PARTITION BY i_brand) AS distinct_categories_per_brand,
  sales_rank,
  CASE
    WHEN ws_net_paid > (
      SELECT AVG(ws_net_paid)
      FROM web_sales
      WHERE ws_ship_date_sk = 2452640
    ) THEN 'ABOVE_AVG'
    ELSE 'BELOW_AVG'
  END AS net_paid_category
FROM ranked
WHERE sales_rank <= 5
ORDER BY ws_net_paid DESC
LIMIT 100
