WITH combined AS (
  SELECT
    s.s_store_id,
    s.s_market_id,
    s.s_hours,
    sm_cr.sm_ship_mode_id AS return_ship_mode,
    sm_ws.sm_ship_mode_id AS web_ship_mode,
    cd.cd_gender,
    cd.cd_marital_status,
    c.c_customer_id,
    cr.cr_reversed_charge,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ws.ws_net_paid,
    ws.ws_net_profit,
    wsite.web_state
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE s.s_hours = '8AM-8AM'
    AND s.s_market_id IN (3, 6)
    AND sm_cr.sm_type = 'AIR'
    AND cd.cd_marital_status = 'M'
    AND cr.cr_reversed_charge > 100
    AND ws.ws_net_paid >= 500
    AND wsite.web_state IN (
          SELECT DISTINCT ws2.web_state
          FROM web_site ws2
          WHERE ws2.web_gmt_offset > 0
        )
)
SELECT
  s_store_id,
  s_market_id,
  return_ship_mode,
  COUNT(DISTINCT c_customer_id) AS distinct_customers,
  SUM(cr_net_loss) AS total_return_loss,
  SUM(ss_net_paid) AS total_store_net_paid,
  SUM(ws_net_paid) AS total_web_net_paid,
  AVG(cr_return_quantity) AS avg_return_qty
FROM combined
GROUP BY
  s_store_id,
  s_market_id,
  return_ship_mode
HAVING SUM(ss_net_profit) > (
        SELECT AVG(ws_sub.ws_net_profit)
        FROM (SELECT ws.ws_net_profit FROM web_sales ws) ws_sub
      )
ORDER BY total_return_loss DESC
LIMIT 100
