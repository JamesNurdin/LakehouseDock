WITH ws_agg AS (
  SELECT
    t.t_hour,
    hd.hd_buy_potential,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE t.t_shift = 'Evening' AND hd.hd_buy_potential = '500-1000'
  GROUP BY t.t_hour, hd.hd_buy_potential
),
sr_agg AS (
  SELECT
    t.t_hour,
    hd.hd_buy_potential,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
  FROM store_returns sr
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE t.t_shift = 'Evening' AND hd.hd_buy_potential = '500-1000'
  GROUP BY t.t_hour, hd.hd_buy_potential
),
cr_agg AS (
  SELECT
    t.t_hour,
    hd.hd_buy_potential,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS num_catalog_returns
  FROM catalog_returns cr
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE t.t_shift = 'Evening' AND hd.hd_buy_potential = '500-1000'
  GROUP BY t.t_hour, hd.hd_buy_potential
)
SELECT
  ws.t_hour,
  ws.hd_buy_potential,
  ws.total_net_profit,
  sr.total_store_net_loss,
  cr.total_catalog_net_loss,
  (ws.total_net_profit - COALESCE(sr.total_store_net_loss, 0) - COALESCE(cr.total_catalog_net_loss, 0)) AS net_profit_after_losses,
  ws.num_orders,
  sr.num_returns,
  cr.num_catalog_returns
FROM ws_agg ws
LEFT JOIN sr_agg sr ON ws.t_hour = sr.t_hour AND ws.hd_buy_potential = sr.hd_buy_potential
LEFT JOIN cr_agg cr ON ws.t_hour = cr.t_hour AND ws.hd_buy_potential = cr.hd_buy_potential
ORDER BY net_profit_after_losses DESC
LIMIT 50
