WITH catalog AS (
  SELECT
    ca.ca_state AS state,
    'Catalog' AS channel,
    cs.cs_order_number AS order_number,
    cs.cs_net_profit AS net_profit,
    CAST(0.0 AS decimal(7,2)) AS return_loss,
    CAST(NULL AS varchar) AS return_reason
  FROM catalog_sales cs
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450825
),
web AS (
  SELECT
    ca.ca_state AS state,
    'Web' AS channel,
    ws.ws_order_number AS order_number,
    ws.ws_net_profit AS net_profit,
    COALESCE(wr.wr_net_loss, CAST(0.0 AS decimal(7,2))) AS return_loss,
    r.r_reason_desc AS return_reason
  FROM web_sales ws
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450825
)
SELECT
  state,
  channel,
  COALESCE(return_reason, 'No Return') AS return_reason,
  COUNT(DISTINCT order_number) AS orders,
  SUM(net_profit) AS total_net_profit,
  SUM(return_loss) AS total_return_loss,
  SUM(net_profit) - SUM(return_loss) AS net_profit_after_returns,
  ROUND((SUM(CASE WHEN return_loss > 0 THEN 1 ELSE 0 END) * 100.0) / NULLIF(COUNT(DISTINCT order_number), 0), 2) AS return_rate_percent,
  RANK() OVER (PARTITION BY state ORDER BY SUM(net_profit) - SUM(return_loss) DESC) AS profit_rank
FROM (
  SELECT * FROM catalog
  UNION ALL
  SELECT * FROM web
) s
GROUP BY state, channel, return_reason
HAVING COUNT(DISTINCT order_number) >= 5
ORDER BY net_profit_after_returns DESC
LIMIT 100
