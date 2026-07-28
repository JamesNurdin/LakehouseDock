WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        d.d_year,
        sm.sm_carrier,
        sm.sm_contract,
        wsite.web_name,
        c.c_email_address
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
      AND regexp_like(sm.sm_contract, '^[A-Z]{5,}$')
      AND wsite.web_name LIKE '%Online%'
      AND regexp_like(c.c_email_address, '.*@example\\.com$')
)
SELECT
    carrier,
    contract,
    COUNT(DISTINCT order_number) AS order_cnt,
    SUM(net_profit) AS total_profit,
    ROUND(SUM(net_profit) / avg_yearly_profit, 2) AS profit_vs_avg,
    CONCAT(carrier, '-', SUBSTRING(contract, 1, 4)) AS carrier_contract_key
FROM (
    SELECT
        fs.ws_order_number AS order_number,
        fs.ws_net_profit AS net_profit,
        fs.sm_carrier AS carrier,
        fs.sm_contract AS contract,
        (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
            JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2020
        ) AS avg_yearly_profit
    FROM filtered_sales fs
) sub
GROUP BY carrier, contract, avg_yearly_profit
HAVING SUM(net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
