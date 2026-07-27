WITH
  sales AS (
    SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      'Sales' AS metric_type,
      SUM(ws.ws_net_profit) AS metric_value
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_name = 'Online Store'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY sm.sm_ship_mode_id
  ),
  returns AS (
    SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      'Return' AS metric_type,
      SUM(wr.wr_net_loss) AS metric_value
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE wr.wr_return_amt_inc_tax > 100.0
    GROUP BY sm.sm_ship_mode_id
  )
SELECT ship_mode_id, metric_type, metric_value
FROM sales
UNION ALL
SELECT ship_mode_id, metric_type, metric_value
FROM returns
ORDER BY ship_mode_id, metric_type
