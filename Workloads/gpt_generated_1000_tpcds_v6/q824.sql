WITH date_2020 AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2020
)
SELECT state,
       total_profit,
       channel
FROM (
    SELECT ca.ca_state AS state,
           SUM(cs.cs_net_profit) AS total_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_2020 d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_state = ca.ca_state
          AND ca2.ca_county = 'Washington County'
    )
    GROUP BY ca.ca_state
    HAVING SUM(cs.cs_net_profit) > 10000

    UNION ALL

    SELECT ca.ca_state AS state,
           SUM(ws.ws_net_profit) AS total_profit,
           'web' AS channel
    FROM web_sales ws
    JOIN date_2020 d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IN ('Fairview', 'Oakland')
    GROUP BY ca.ca_state
    HAVING SUM(ws.ws_net_profit) > 8000
) AS combined
ORDER BY total_profit DESC
LIMIT 100
