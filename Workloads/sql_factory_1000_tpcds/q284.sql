WITH store_city AS (
    SELECT ca.ca_city,
           SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
),
web_city AS (
    SELECT ca.ca_city,
           SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
),
city_profit AS (
    SELECT COALESCE(st.ca_city, wc.ca_city) AS city,
           COALESCE(st.store_profit, 0) AS store_profit,
           COALESCE(wc.web_profit, 0) AS web_profit,
           COALESCE(st.store_profit, 0) + COALESCE(wc.web_profit, 0) AS total_profit
    FROM store_city st
    FULL OUTER JOIN web_city wc
        ON st.ca_city = wc.ca_city
)
SELECT
    cp.city,
    cp.store_profit,
    cp.web_profit,
    cp.total_profit,
    DENSE_RANK() OVER (ORDER BY cp.total_profit DESC) AS profit_rank,
    CASE 
        WHEN cp.total_profit >= 500000 THEN 'Very High'
        WHEN cp.total_profit >= 200000 THEN 'High'
        WHEN cp.total_profit >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    SUM(cp.total_profit) OVER (ORDER BY cp.total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM city_profit cp
ORDER BY profit_rank
LIMIT 5
