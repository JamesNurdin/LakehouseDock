WITH sr AS (
  SELECT
    sr.sr_returned_date_sk AS date_sk,
    s.s_store_sk AS store_sk,
    s.s_store_name,
    COUNT(*) AS store_return_cnt,
    SUM(sr.sr_net_loss) AS store_net_loss
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE d.d_year = 2001
    AND d.d_qoy = 2
    AND t.t_hour BETWEEN 9 AND 17
    AND EXISTS (
      SELECT 1 FROM customer_address ca
      WHERE ca.ca_address_sk = sr.sr_addr_sk
        AND ca.ca_state = 'CA'
    )
  GROUP BY sr.sr_returned_date_sk, s.s_store_sk, s.s_store_name
),
cr AS (
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    COUNT(*) AS catalog_return_cnt,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    cc.cc_name,
    sm.sm_carrier
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND sm.sm_carrier = 'DHL'
    AND cc.cc_state = 'CA'
  GROUP BY cr.cr_returned_date_sk, cc.cc_name, sm.sm_carrier
),
wr AS (
  SELECT
    wr.wr_returned_date_sk AS date_sk,
    COUNT(*) AS web_return_cnt,
    SUM(wr.wr_net_loss) AS web_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND wr.wr_return_tax > 30
    AND wr.wr_return_ship_cost < 500
  GROUP BY wr.wr_returned_date_sk
),
ws AS (
  SELECT
    ws.ws_sold_date_sk AS date_sk,
    COUNT(*) AS web_sales_cnt,
    SUM(ws.ws_net_profit) AS web_net_profit,
    sm.sm_carrier
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND sm.sm_carrier = 'DHL'
    AND ws.ws_quantity > 1
  GROUP BY ws.ws_sold_date_sk, sm.sm_carrier
),
inv AS (
  SELECT
    inv.inv_date_sk AS date_sk,
    SUM(inv.inv_quantity_on_hand) AS total_inventory
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND inv.inv_quantity_on_hand > 100
  GROUP BY inv.inv_date_sk
)
SELECT
  d.d_year,
  d.d_month_seq,
  COALESCE(sr.store_return_cnt, 0) AS store_return_cnt,
  COALESCE(cr.catalog_return_cnt, 0) AS catalog_return_cnt,
  COALESCE(wr.web_return_cnt, 0) AS web_return_cnt,
  COALESCE(ws.web_sales_cnt, 0) AS web_sales_cnt,
  COALESCE(inv.total_inventory, 0) AS total_inventory,
  COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) AS total_net_loss,
  COALESCE(ws.web_net_profit, 0) AS total_web_net_profit,
  cr.cc_name,
  cr.sm_carrier,
  sr.s_store_name
FROM date_dim d
LEFT JOIN sr ON sr.date_sk = d.d_date_sk
LEFT JOIN cr ON cr.date_sk = d.d_date_sk
LEFT JOIN wr ON wr.date_sk = d.d_date_sk
LEFT JOIN ws ON ws.date_sk = d.d_date_sk
LEFT JOIN inv ON inv.date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_qoy = 2
ORDER BY d.d_year, d.d_month_seq, sr.s_store_name
