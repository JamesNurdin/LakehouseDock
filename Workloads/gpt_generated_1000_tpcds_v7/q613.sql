WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_customer_sk,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT
    wsite.web_site_id,
    regexp_extract(wsite.web_name, '(.*) Market', 1) AS market_name,
    CONCAT(wsite.web_city, ', ', wsite.web_state) AS location,
    SUM(fs.ws_net_profit) AS total_profit,
    COUNT(*) AS order_count
FROM filtered_sales fs
JOIN web_sales ws ON ws.ws_sold_date_sk = fs.ws_sold_date_sk
                AND ws.ws_web_site_sk = fs.ws_web_site_sk
                AND ws.ws_bill_customer_sk = fs.ws_bill_customer_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
WHERE wsite.web_name LIKE '%Market%'
  AND regexp_like(cust.c_first_name, '^A.*')
  AND SUBSTRING(wsite.web_zip, 1, 2) = '94'
GROUP BY
    wsite.web_site_id,
    regexp_extract(wsite.web_name, '(.*) Market', 1),
    CONCAT(wsite.web_city, ', ', wsite.web_state)
ORDER BY total_profit DESC
LIMIT 10
