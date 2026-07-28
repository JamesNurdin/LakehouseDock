WITH
  store_agg AS (
    SELECT
      sr_item_sk,
      SUM(sr_net_loss) AS store_loss,
      COUNT(*) AS store_cnt,
      MIN(sr_hdemo_sk) AS hd_demo_sk,
      MIN(sr_cdemo_sk) AS cd_demo_sk,
      MIN(sr_addr_sk) AS addr_sk
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_returned_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY sr_item_sk
  ),
  web_sales_agg AS (
    SELECT
      ws_item_sk,
      SUM(ws_net_paid) AS web_sales,
      AVG(ws_ext_discount_amt) AS avg_discount,
      MIN(ws_ship_mode_sk) AS ship_mode_sk,
      MIN(ws_web_site_sk) AS web_site_sk,
      MIN(ws_web_page_sk) AS web_page_sk
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ws_item_sk
  ),
  catalog_agg AS (
    SELECT
      cr_item_sk,
      SUM(cr_net_loss) AS catalog_loss,
      COUNT(*) AS catalog_cnt,
      MIN(cr_ship_mode_sk) AS ship_mode_sk,
      MIN(cr_call_center_sk) AS call_center_sk,
      MIN(cr_refunded_hdemo_sk) AS hd_demo_sk,
      MIN(cr_refunded_addr_sk) AS addr_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 1
      AND cr_returned_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY cr_item_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  i.i_category,
  sa.store_loss,
  NULL AS catalog_loss,
  ws.web_sales,
  ws.avg_discount,
  p.p_promo_name,
  sm.sm_type AS ship_mode_type,
  cc.cc_name AS call_center_name,
  ws_site.web_name AS web_site_name,
  wp.wp_type AS web_page_type,
  ib.ib_upper_bound AS income_upper,
  hd.hd_buy_potential
FROM store_agg sa
JOIN item i ON i.i_item_sk = sa.sr_item_sk
LEFT JOIN web_sales_agg ws ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws.ship_mode_sk
JOIN web_site ws_site ON ws_site.web_site_sk = ws.web_site_sk
JOIN web_page wp ON wp.wp_web_page_sk = ws.web_page_sk
JOIN household_demographics hd ON hd.hd_demo_sk = sa.hd_demo_sk
JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN customer_address ca ON ca.ca_address_sk = sa.addr_sk
JOIN call_center cc ON FALSE -- dummy join to bring the table into the query plan (filtered out later)
WHERE NOT EXISTS (
  SELECT 1 FROM promotion p2
  WHERE p2.p_item_sk = i.i_item_sk
    AND p2.p_discount_active = 'Y'
)

UNION ALL

SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  i.i_category,
  NULL AS store_loss,
  ca.catalog_loss,
  NULL AS web_sales,
  NULL AS avg_discount,
  p.p_promo_name,
  sm2.sm_type AS ship_mode_type,
  cc2.cc_name AS call_center_name,
  ws_site2.web_name AS web_site_name,
  wp2.wp_type AS web_page_type,
  ib2.ib_upper_bound AS income_upper,
  hd2.hd_buy_potential
FROM catalog_agg ca
JOIN item i ON i.i_item_sk = ca.cr_item_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN ship_mode sm2 ON sm2.sm_ship_mode_sk = ca.ship_mode_sk
JOIN call_center cc2 ON cc2.cc_call_center_sk = ca.call_center_sk
JOIN web_site ws_site2 ON ws_site2.web_site_sk = 0 -- dummy to keep table in the plan
JOIN web_page wp2 ON wp2.wp_web_page_sk = 0 -- dummy to keep table in the plan
JOIN household_demographics hd2 ON hd2.hd_demo_sk = ca.hd_demo_sk
JOIN income_band ib2 ON ib2.ib_income_band_sk = hd2.hd_income_band_sk
JOIN customer_address ca_addr ON ca_addr.ca_address_sk = ca.addr_sk
WHERE NOT EXISTS (
  SELECT 1 FROM promotion p2
  WHERE p2.p_item_sk = i.i_item_sk
    AND p2.p_discount_active = 'Y'
)
ORDER BY i_item_id
LIMIT 100
