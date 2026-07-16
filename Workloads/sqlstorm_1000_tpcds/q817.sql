SELECT t.year, t.state, SUM(t.net_profit) AS total_profit
FROM (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk

    UNION ALL

    SELECT d.d_year AS year,
           ca.ca_state AS state,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk

    UNION ALL

    SELECT d.d_year AS year,
           ca.ca_state AS state,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN customer_address ca ON ca.ca_address_sk = ws.ws_bill_addr_sk
) t
GROUP BY t.year, t.state
ORDER BY total_profit DESC
LIMIT 10
