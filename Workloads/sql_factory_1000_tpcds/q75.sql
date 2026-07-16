WITH catalog_sales_addr AS (
    SELECT
        cs.cs_bill_addr_sk AS bill_addr_sk,
        ca.ca_state,
        ca.ca_city,
        cs.cs_sold_date_sk AS sold_date,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
),
web_sales_addr AS (
    SELECT
        ws.ws_bill_addr_sk AS bill_addr_sk,
        ca.ca_state,
        ca.ca_city,
        ws.ws_sold_date_sk AS sold_date,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
combined AS (
    SELECT bill_addr_sk, ca_state, ca_city, sold_date, net_profit FROM catalog_sales_addr
    UNION ALL
    SELECT bill_addr_sk, ca_state, ca_city, sold_date, net_profit FROM web_sales_addr
),
ordered AS (
    SELECT
        bill_addr_sk,
        ca_state,
        ca_city,
        sold_date,
        net_profit,
        SUM(net_profit) OVER (PARTITION BY bill_addr_sk ORDER BY sold_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM combined
)
SELECT
    bill_addr_sk,
    ca_state,
    ca_city,
    MAX(sold_date) AS last_sold_date,
    MAX(cumulative_profit) AS total_cumulative_profit,
    RANK() OVER (ORDER BY MAX(cumulative_profit) DESC) AS profit_rank,
    CASE
        WHEN MAX(cumulative_profit) >= 500000 THEN 'Platinum'
        WHEN MAX(cumulative_profit) >= 200000 THEN 'Gold'
        WHEN MAX(cumulative_profit) >= 50000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM ordered
GROUP BY bill_addr_sk, ca_state, ca_city
ORDER BY profit_rank
LIMIT 20
