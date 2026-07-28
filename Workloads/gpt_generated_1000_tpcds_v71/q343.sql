WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_addr_sk,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    ss.ss_ticket_number,
    ss.ss_net_profit,
    d.d_year,
    i.i_category,
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    p.p_channel_radio,
    ws.ws_net_profit AS web_profit,
    ws.ws_ship_mode_sk,
    sm.sm_type AS ship_type,
    sr.sr_net_loss,
    r.r_reason_desc
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN web_sales ws ON ss.ss_ticket_number = ws.ws_order_number
  LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
)
SELECT
  d_year,
  s_store_name,
  i_category,
  COUNT(DISTINCT p_promo_name) AS distinct_promotions,
  SUM(ss_net_profit) AS total_store_profit,
  SUM(COALESCE(web_profit, 0)) AS total_web_profit,
  SUM(COALESCE(sr_net_loss, 0)) * -1 AS net_return_gain,
  CASE
    WHEN SUM(ss_net_profit) > 10000 THEN 'High'
    WHEN SUM(ss_net_profit) > 0 THEN 'Medium'
    ELSE 'Low'
  END AS profit_level,
  RANK() OVER (PARTITION BY d_year ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM base
JOIN call_center cc ON cc.cc_closed_date_sk = base.ss_sold_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = base.ss_sold_date_sk
WHERE
  s_state = 'TX'
  AND d_year = 2001
  AND p_channel_radio = 'N'
GROUP BY
  d_year,
  s_store_name,
  i_category
ORDER BY profit_rank
LIMIT 100
