WITH
  store_sales_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_coupon_amt) AS total_coupons,
      COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk, ss.ss_item_sk
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_web_site_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      SUM(ws.ws_ext_sales_price) AS web_total_sales,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND ws.ws_sales_price > 50
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk, ws.ws_sold_time_sk, ws.ws_item_sk
  ),
  catalog_info AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_item_sk,
      cp.cp_catalog_page_id,
      w.w_warehouse_name,
      p.p_promo_id,
      d.d_year
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
  ),
  intersect_items AS (
    SELECT ss_item_sk FROM store_sales
    INTERSECT
    SELECT ws_item_sk FROM web_sales
  ),
  full_inventory_promo AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      p.p_promo_id,
      p.p_discount_active
    FROM (
      SELECT inv_item_sk, inv_quantity_on_hand FROM inventory
    ) inv
    FULL OUTER JOIN (
      SELECT p_item_sk, p_promo_id, p_discount_active FROM promotion
    ) p
      ON inv.inv_item_sk = p.p_item_sk
  )
SELECT
  s.s_store_name,
  d.d_year,
  i.i_category,
  SUM(sa.total_sales) AS store_total_sales,
  SUM(wsag.web_total_sales) AS web_total_sales,
  COUNT(DISTINCT sa.distinct_customers) AS store_customer_count,
  COUNT(DISTINCT wsag.web_distinct_customers) AS web_customer_count,
  MIN(i.i_current_price) AS min_price,
  MAX(i.i_current_price) AS max_price,
  AVG(i.i_current_price) AS avg_price,
  COUNT(DISTINCT fip.p_promo_id) FILTER (WHERE fip.p_discount_active = 'Y') AS active_promo_count,
  ci.cp_catalog_page_id AS catalog_page_id,
  word
FROM store_sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN web_sales_agg wsag ON i.i_item_sk = wsag.ws_item_sk
JOIN intersect_items ii ON i.i_item_sk = ii.ss_item_sk
JOIN full_inventory_promo fip ON i.i_item_sk = fip.inv_item_sk
JOIN catalog_info ci ON i.i_item_sk = ci.cr_item_sk
CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
WHERE i.i_category_id IN (4, 9)
  AND s.s_state = 'CA'
  AND i.i_size = 'medium'
  AND EXISTS (
    SELECT 1 FROM store_returns sr
    WHERE sr.sr_store_sk = s.s_store_sk
      AND sr.sr_net_loss > 0
  )
GROUP BY s.s_store_name, d.d_year, i.i_category, ci.cp_catalog_page_id, word
HAVING SUM(sa.total_sales) > 10000
ORDER BY store_total_sales DESC
LIMIT 100
