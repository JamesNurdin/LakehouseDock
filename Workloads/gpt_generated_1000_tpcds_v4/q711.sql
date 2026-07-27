WITH avg_store_profit AS (
    SELECT AVG(ss2.ss_net_profit) AS avg_profit
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_fy_year = 1915
),
avg_web_profit AS (
    SELECT AVG(ws2.ws_net_profit) AS avg_profit
    FROM web_sales ws2
    JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_fy_year = 1915
)
SELECT state, fiscal_year, total_profit, channel
FROM (
    SELECT
        ca.ca_state AS state,
        d.d_fy_year AS fiscal_year,
        SUM(ss.ss_net_profit) AS total_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_fy_year = 1915
      AND ss.ss_net_profit > (SELECT avg_profit FROM avg_store_profit)
    GROUP BY ca.ca_state, d.d_fy_year

    UNION ALL

    SELECT
        ca.ca_state AS state,
        d.d_fy_year AS fiscal_year,
        SUM(ws.ws_net_profit) AS total_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_fy_year = 1915
      AND ws.ws_net_profit > (SELECT avg_profit FROM avg_web_profit)
    GROUP BY ca.ca_state, d.d_fy_year
) AS combined
ORDER BY fiscal_year DESC, total_profit DESC
LIMIT 100
