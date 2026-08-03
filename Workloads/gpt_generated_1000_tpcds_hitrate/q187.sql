WITH ws AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    ws.ws_bill_cdemo_sk AS bill_demo_sk,
    ws.ws_ship_cdemo_sk AS ship_demo_sk,
    ws.ws_bill_addr_sk AS bill_addr_sk,
    ws.ws_ship_addr_sk AS ship_addr_sk,
    wp.wp_type,
    p.p_channel_email AS promo_channel_email
  FROM web_sales ws
  JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
)
SELECT
  s.s_state AS store_state,
  ws.promo_channel_email,
  SUM(ws.ws_net_profit) AS total_web_profit,
  SUM(sr.sr_net_loss) AS total_store_loss,
  SUM(cr.cr_net_loss) AS total_catalog_loss,
  CASE WHEN SUM(ws.ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
FROM ws
JOIN store_returns sr
  ON sr.sr_cdemo_sk = ws.bill_demo_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_store
  ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN catalog_returns cr
  ON cr.cr_refunded_cdemo_sk = ws.ship_demo_sk
JOIN reason r_catalog
  ON cr.cr_reason_sk = r_catalog.r_reason_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
  ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
GROUP BY s.s_state, ws.promo_channel_email
ORDER BY total_web_profit DESC
LIMIT 100
