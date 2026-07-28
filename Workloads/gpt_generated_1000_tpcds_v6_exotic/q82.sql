WITH
  store_agg AS (
    SELECT
      ss_customer_sk AS customer_sk,
      ss_sold_time_sk AS sold_time_sk,
      ss_promo_sk AS promo_sk,
      CAST(NULL AS integer) AS ship_mode_sk,
      CAST(NULL AS integer) AS warehouse_sk,
      CAST(NULL AS integer) AS web_page_sk,
      SUM(ss_ext_sales_price) AS sales_total,
      COUNT(*) AS sales_cnt,
      'store' AS channel
    FROM store_sales
    WHERE ss_ext_sales_price > 200
      AND ss_quantity >= 2
    GROUP BY ss_customer_sk, ss_sold_time_sk, ss_promo_sk
  ),
  web_agg AS (
    SELECT
      ws_bill_customer_sk AS customer_sk,
      ws_sold_time_sk AS sold_time_sk,
      ws_promo_sk AS promo_sk,
      ws_ship_mode_sk AS ship_mode_sk,
      ws_warehouse_sk AS warehouse_sk,
      ws_web_page_sk AS web_page_sk,
      SUM(ws_ext_sales_price) AS sales_total,
      COUNT(*) AS sales_cnt,
      'web' AS channel
    FROM web_sales
    WHERE ws_ext_sales_price > 200
      AND ws_quantity >= 2
      AND ws_ship_mode_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk, ws_sold_time_sk, ws_promo_sk, ws_ship_mode_sk, ws_warehouse_sk, ws_web_page_sk
  ),
  combined_sales AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  ),
  promo_active AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
  )
SELECT
  c.c_customer_id,
  ca.ca_city,
  td.t_hour,
  p.p_promo_name,
  SUM(cs.sales_total)               AS total_sales,
  COUNT(DISTINCT cs.channel)        AS sales_channels,
  AVG(cs.sales_total)               AS avg_sales_per_group,
  MIN(cs.sales_total)               AS min_sales,
  MAX(cs.sales_total)               AS max_sales
FROM combined_sales cs
JOIN customer c        ON cs.customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN time_dim td        ON cs.sold_time_sk = td.t_time_sk
JOIN promotion p        ON cs.promo_sk = p.p_promo_sk
LEFT JOIN ship_mode sm  ON cs.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w   ON cs.warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_page wp   ON cs.web_page_sk = wp.wp_web_page_sk
WHERE EXISTS (SELECT 1 FROM promo_active pa WHERE pa.p_promo_sk = cs.promo_sk)
  AND ca.ca_state = 'CA'
  AND w.w_city = 'San Francisco'
  AND sm.sm_carrier = 'UPS'
GROUP BY
  c.c_customer_id,
  ca.ca_city,
  td.t_hour,
  p.p_promo_name
HAVING SUM(cs.sales_total) > 1000
ORDER BY total_sales DESC
LIMIT 100
