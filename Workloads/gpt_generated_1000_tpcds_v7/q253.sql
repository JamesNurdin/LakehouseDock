WITH store_agg AS (
  SELECT
    i.i_item_id AS item_id,
    ss.ss_sold_date_sk AS sold_date_sk,
    SUM(ss.ss_net_paid) AS total_net_paid,
    'store' AS sales_channel
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE i.i_current_price BETWEEN 20 AND 200
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
  GROUP BY i.i_item_id, ss.ss_sold_date_sk
),
web_agg AS (
  SELECT
    i.i_item_id AS item_id,
    ws.ws_sold_date_sk AS sold_date_sk,
    SUM(ws.ws_net_paid) AS total_net_paid,
    'web' AS sales_channel
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE i.i_current_price BETWEEN 20 AND 200
    AND w.web_state = 'CA'
    AND sm.sm_code = 'AIR'
  GROUP BY i.i_item_id, ws.ws_sold_date_sk
)
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_net_paid DESC
LIMIT 100
