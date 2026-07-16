WITH hourly_metrics AS (
  SELECT
    td.t_hour,
    td.t_shift,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) AS net_margin,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders
  FROM time_dim td
  JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
  WHERE td.t_hour BETWEEN 8 AND 20
    AND ws.ws_ship_mode_sk IS NOT NULL
    AND cr.cr_return_quantity > 0
    AND cr.cr_reason_sk = 20
  GROUP BY td.t_hour, td.t_shift
)
SELECT
  t_hour,
  t_shift,
  total_web_profit,
  total_return_loss,
  net_margin,
  web_orders,
  return_orders,
  RANK() OVER (ORDER BY net_margin DESC) AS profit_rank
FROM hourly_metrics
ORDER BY profit_rank
LIMIT 10
