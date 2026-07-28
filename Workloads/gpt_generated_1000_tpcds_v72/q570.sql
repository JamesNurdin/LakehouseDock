WITH
  catalog_agg AS (
    SELECT
      cs_promo_sk AS promo_sk,
      cs_ship_mode_sk AS ship_mode_sk,
      cs_bill_cdemo_sk AS cd_demo_sk,
      SUM(cs_ext_sales_price) AS catalog_sales_amount,
      COUNT(*) AS catalog_order_cnt
    FROM catalog_sales
    WHERE cs_quantity > 50
      AND cs_ext_list_price > 1000
    GROUP BY cs_promo_sk, cs_ship_mode_sk, cs_bill_cdemo_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_promo_sk AS promo_sk,
      ws.ws_ship_mode_sk AS ship_mode_sk,
      ws.ws_bill_cdemo_sk AS cd_demo_sk,
      ws.ws_web_site_sk AS site_sk,
      ws.ws_web_page_sk AS page_sk,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      COUNT(*) AS web_order_cnt
    FROM web_sales ws
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_page wp
      ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site wsite
      ON wsite.web_site_sk = ws.ws_web_site_sk
    WHERE ws.ws_quantity > 30
      AND ws.ws_ext_list_price > 800
    GROUP BY ws.ws_promo_sk, ws.ws_ship_mode_sk, ws.ws_bill_cdemo_sk, ws.ws_web_site_sk, ws.ws_web_page_sk
  ),
  combined_sales AS (
    SELECT
      promo_sk,
      ship_mode_sk,
      cd_demo_sk,
      NULL AS site_sk,
      NULL AS page_sk,
      catalog_sales_amount,
      catalog_order_cnt,
      0.0 AS web_sales_amount,
      0 AS web_order_cnt,
      'catalog' AS source
    FROM catalog_agg
    UNION ALL
    SELECT
      promo_sk,
      ship_mode_sk,
      cd_demo_sk,
      site_sk,
      page_sk,
      0.0 AS catalog_sales_amount,
      0 AS catalog_order_cnt,
      web_sales_amount,
      web_order_cnt,
      'web' AS source
    FROM web_agg
  )
SELECT
  p.p_promo_id,
  sm.sm_carrier,
  cd.cd_marital_status,
  ws.web_name,
  wp.wp_type,
  SUM(final_sales.sales_amount) AS total_sales_amount,
  SUM(final_sales.order_cnt) AS total_orders,
  CASE WHEN SUM(final_sales.sales_amount) > 0 THEN
       CASE WHEN SUM(final_sales.sales_amount) > 100000 THEN 'High'
            ELSE 'Low'
       END
       ELSE 'None'
  END AS sales_volume_category
FROM (
  SELECT
    promo_sk,
    ship_mode_sk,
    cd_demo_sk,
    site_sk,
    page_sk,
    catalog_sales_amount AS sales_amount,
    catalog_order_cnt AS order_cnt,
    source
  FROM combined_sales
  WHERE source = 'catalog'
  UNION ALL
  SELECT
    promo_sk,
    ship_mode_sk,
    cd_demo_sk,
    site_sk,
    page_sk,
    web_sales_amount AS sales_amount,
    web_order_cnt AS order_cnt,
    source
  FROM combined_sales
  WHERE source = 'web'
) AS final_sales
JOIN promotion p
  ON p.p_promo_sk = final_sales.promo_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = final_sales.ship_mode_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = final_sales.cd_demo_sk
LEFT JOIN web_site ws
  ON ws.web_site_sk = final_sales.site_sk
LEFT JOIN web_page wp
  ON wp.wp_web_page_sk = final_sales.page_sk
WHERE sm.sm_carrier = 'UPS'
  AND cd.cd_marital_status = 'M'
  AND p.p_discount_active = 'Y'
GROUP BY p.p_promo_id, sm.sm_carrier, cd.cd_marital_status, ws.web_name, wp.wp_type
ORDER BY total_sales_amount DESC
LIMIT 100
