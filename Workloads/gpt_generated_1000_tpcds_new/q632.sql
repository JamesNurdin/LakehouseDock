WITH
  store_agg AS (
    SELECT
      ss_item_sk,
      SUM(ss_net_profit) AS store_profit,
      COUNT(*) AS store_sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450818 AND 2450827
    GROUP BY ss_item_sk
  ),
  cs_array AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_ship_mode_sk,
      cs.cs_order_number,
      ARRAY[
        CAST(cs.cs_quantity AS DOUBLE),
        CAST(cs.cs_sales_price AS DOUBLE),
        CAST(cs.cs_ext_discount_amt AS DOUBLE)
      ] AS metrics,
      cs.cs_ext_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 20
  )
SELECT DISTINCT
  i.i_item_id,
  p.p_promo_name,
  sm.sm_ship_mode_id,
  ws.ws_web_site_sk,
  wp.wp_web_page_sk,
  COALESCE(sa.store_profit, 0) AS store_profit,
  SUM(ca.cs_ext_sales_price) AS catalog_sales_total,
  CASE WHEN SUM(ca.cs_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
  val AS metric_value
FROM cs_array ca
JOIN item i ON ca.cs_item_sk = i.i_item_sk
JOIN promotion p ON ca.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN store_agg sa ON i.i_item_sk = sa.ss_item_sk
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
CROSS JOIN UNNEST(ca.metrics) AS t(val)
WHERE EXISTS (
  SELECT 1
  FROM web_sales ws2
  WHERE ws2.ws_item_sk = i.i_item_sk
    AND ws2.ws_quantity > 5
)
GROUP BY
  i.i_item_id,
  p.p_promo_name,
  sm.sm_ship_mode_id,
  ws.ws_web_site_sk,
  wp.wp_web_page_sk,
  sa.store_profit,
  val

UNION DISTINCT

SELECT DISTINCT
  i2.i_item_id,
  p2.p_promo_name,
  sm2.sm_ship_mode_id,
  ws2.ws_web_site_sk,
  wp2.wp_web_page_sk,
  COALESCE(sa2.store_profit, 0) AS store_profit,
  SUM(ca2.cs_ext_sales_price) AS catalog_sales_total,
  CASE WHEN SUM(ca2.cs_ext_sales_price) > 5000 THEN 'MEDIUM' ELSE 'SMALL' END AS sales_category,
  val2 AS metric_value
FROM cs_array ca2
JOIN item i2 ON ca2.cs_item_sk = i2.i_item_sk
JOIN promotion p2 ON ca2.cs_promo_sk = p2.p_promo_sk
JOIN ship_mode sm2 ON ca2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
LEFT JOIN store_agg sa2 ON i2.i_item_sk = sa2.ss_item_sk
JOIN web_sales ws2 ON i2.i_item_sk = ws2.ws_item_sk
JOIN web_page wp2 ON ws2.ws_web_page_sk = wp2.wp_web_page_sk
JOIN web_site wsite2 ON ws2.ws_web_site_sk = wsite2.web_site_sk
CROSS JOIN UNNEST(ca2.metrics) AS t2(val2)
WHERE EXISTS (
  SELECT 1
  FROM store_sales ss2
  WHERE ss2.ss_item_sk = i2.i_item_sk
    AND ss2.ss_quantity > 3
)
GROUP BY
  i2.i_item_id,
  p2.p_promo_name,
  sm2.sm_ship_mode_id,
  ws2.ws_web_site_sk,
  wp2.wp_web_page_sk,
  sa2.store_profit,
  val2

ORDER BY catalog_sales_total DESC, i_item_id
LIMIT 100
