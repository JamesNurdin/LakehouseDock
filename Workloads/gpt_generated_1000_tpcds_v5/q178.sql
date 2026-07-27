WITH store_agg AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_promo_sk,
    ss.ss_store_sk,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(*) AS store_txn_cnt,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT sr.sr_reason_sk) AS distinct_return_reasons
  FROM store_sales ss
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  GROUP BY ss.ss_sold_date_sk, ss.ss_promo_sk, ss.ss_store_sk
)
SELECT
  d.d_year,
  p.p_promo_name,
  sm.sm_type,
  CASE
    WHEN sm.sm_type = 'AIR' THEN 'Fast'
    WHEN sm.sm_type = 'RAIL' THEN 'Slow'
    ELSE 'Other'
  END AS shipping_category,
  SUM(sa.store_net_profit) AS total_store_net_profit,
  SUM(ws.ws_net_profit) AS total_web_net_profit,
  SUM(ws.ws_net_paid_inc_ship_tax) AS total_web_net_paid_inc_ship_tax,
  COUNT(DISTINCT p.p_promo_id) AS distinct_store_promos,
  COUNT(DISTINCT p_web.p_promo_id) AS distinct_web_promos,
  COUNT(DISTINCT cc.cc_call_center_id) AS distinct_call_centers
FROM store_agg sa
JOIN date_dim d
  ON sa.ss_sold_date_sk = d.d_date_sk
JOIN promotion p
  ON sa.ss_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN call_center cc
  ON cc.cc_closed_date_sk = d.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p_web
  ON ws.ws_promo_sk = p_web.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d.d_year = 2001
GROUP BY
  d.d_year,
  p.p_promo_name,
  sm.sm_type,
  CASE
    WHEN sm.sm_type = 'AIR' THEN 'Fast'
    WHEN sm.sm_type = 'RAIL' THEN 'Slow'
    ELSE 'Other'
  END
ORDER BY total_store_net_profit DESC
LIMIT 100
