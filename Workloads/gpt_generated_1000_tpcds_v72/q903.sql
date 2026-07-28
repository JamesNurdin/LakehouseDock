WITH cs_sales AS (
    SELECT DISTINCT ca.ca_state AS state,
           SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
),
ws_sales AS (
    SELECT DISTINCT ca.ca_state AS state,
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
)
SELECT state,
       SUM(total_net_paid) AS combined_net_paid
FROM (
    SELECT state, total_net_paid FROM cs_sales
    UNION ALL
    SELECT state, total_net_paid FROM ws_sales
) u
GROUP BY state
ORDER BY combined_net_paid DESC
