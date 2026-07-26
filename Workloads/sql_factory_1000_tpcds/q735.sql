WITH shipment_data AS (
  SELECT
    cs.cs_ship_mode_sk AS ship_mode_sk,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_ship_cost AS ship_cost,
    cs.cs_quantity AS quantity,
    d.d_day_name AS day_name,
    NULL AS page_type,
    NULL AS char_count
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    ws.ws_ship_mode_sk AS ship_mode_sk,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_ship_cost AS ship_cost,
    ws.ws_quantity AS quantity,
    d.d_day_name AS day_name,
    wp.wp_type AS page_type,
    wp.wp_char_count AS char_count
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
  ship_mode_sk,
  COUNT(*) AS total_orders,
  SUM(net_profit) AS total_profit,
  AVG(net_profit) AS avg_profit,
  SUM(ship_cost) AS total_ship_cost,
  AVG(ship_cost) AS avg_ship_cost,
  SUM(quantity) AS total_quantity,
  CASE WHEN AVG(ship_cost) > 50 THEN 'High Cost' ELSE 'Normal Cost' END AS cost_category,
  DENSE_RANK() OVER (ORDER BY AVG(net_profit) DESC) AS profit_rank,
  COUNT(DISTINCT day_name) AS distinct_days_of_week,
  AVG(char_count) AS avg_page_char_count
FROM shipment_data
GROUP BY ship_mode_sk
ORDER BY profit_rank
LIMIT 10
