WITH base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    sr.sr_return_amt,
    sr.sr_net_loss,
    t.t_time_sk,
    t.t_hour,
    t.t_am_pm,
    wp.wp_web_page_sk,
    wp.wp_url,
    ws.ws_ext_ship_cost,
    ws.ws_net_paid_inc_ship_tax,
    ws.ws_quantity,
    wsit.web_site_sk,
    wsit.web_state,
    wsit.web_name
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
  JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE t.t_hour BETWEEN 8 AND 20
    AND t.t_am_pm = 'PM'
    AND ws.ws_ext_ship_cost > 500
    AND wsit.web_state = 'CA'
    AND cs.cs_quantity > 2
)
SELECT
  base.web_state,
  base.web_name,
  base.t_hour,
  base.cs_quantity,
  base.ws_quantity,
  CASE
    WHEN base.cs_net_profit > 0 THEN 'Profitable'
    ELSE 'Loss'
  END AS profit_category,
  base.ws_net_paid_inc_ship_tax,
  ROW_NUMBER() OVER (PARTITION BY base.web_state ORDER BY base.ws_net_paid_inc_ship_tax DESC) AS rn_state,
  (
    SELECT COUNT(*) FROM (
      SELECT DISTINCT ws2.ws_web_page_sk
      FROM web_sales ws2
      WHERE ws2.ws_ext_ship_cost > 800
      INTERSECT
      SELECT DISTINCT wp2.wp_web_page_sk
      FROM web_page wp2
      WHERE wp2.wp_type = 'article'
    ) AS intersect_pages
  ) AS intersect_page_count
FROM base
WHERE EXISTS (
  SELECT 1
  FROM catalog_sales cs2
  WHERE cs2.cs_order_number = base.cs_sold_date_sk
    AND cs2.cs_quantity > 5
)
ORDER BY base.web_state, rn_state
LIMIT 100
