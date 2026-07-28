WITH site_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^A{5,}[A-Z]*@example\\.com$')
      AND c.c_birth_month = 6
)
SELECT
    ws.web_site_id,
    ws.web_name,
    COUNT(DISTINCT ss.ws_bill_customer_sk) AS unique_customers,
    SUM(ss.ws_ext_sales_price) AS total_sales,
    SUM(ss.ws_net_profit) AS total_profit,
    REGEXP_EXTRACT(ws.web_site_id, 'AAAAAAA([A-Z])', 1) AS site_code_char,
    CONCAT(SUBSTRING(ws.web_city, 1, 3), '-', ws.web_state) AS city_state_key
FROM site_sales ss
JOIN web_site ws
    ON ss.ws_web_site_sk = ws.web_site_sk
WHERE ws.web_site_id LIKE 'AAAAAAA%'
  AND EXISTS (
        SELECT 1
        FROM web_sales w2
        WHERE w2.ws_web_site_sk = ws.web_site_sk
          AND w2.ws_ext_discount_amt > 0
      )
GROUP BY
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    REGEXP_EXTRACT(ws.web_site_id, 'AAAAAAA([A-Z])', 1),
    CONCAT(SUBSTRING(ws.web_city, 1, 3), '-', ws.web_state)
ORDER BY total_profit DESC
LIMIT 10
