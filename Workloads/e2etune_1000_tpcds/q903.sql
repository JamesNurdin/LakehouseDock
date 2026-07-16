WITH combined AS (
    SELECT cs.cs_net_profit AS profit,
           'catalog' AS channel,
           t.t_hour AS hour,
           ca.ca_state AS state
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_ship_customer_sk IN (3089367, 9614951, 9865305)
      AND cs.cs_ship_date_sk BETWEEN 2450870 AND 2450900
    UNION ALL
    SELECT ws.ws_net_profit AS profit,
           'web' AS channel,
           t.t_hour AS hour,
           ca.ca_state AS state
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_ship_customer_sk IN (3089367, 9614951, 9865305)
      AND ws.ws_ship_date_sk BETWEEN 2450870 AND 2450900
)
SELECT hour,
       state,
       SUM(profit) AS total_profit,
       SUM(CASE WHEN channel = 'catalog' THEN profit ELSE 0 END) AS catalog_profit,
       SUM(CASE WHEN channel = 'web' THEN profit ELSE 0 END) AS web_profit,
       RANK() OVER (PARTITION BY hour ORDER BY SUM(profit) DESC) AS profit_rank
FROM combined
GROUP BY hour, state
ORDER BY hour, profit_rank
LIMIT 100
