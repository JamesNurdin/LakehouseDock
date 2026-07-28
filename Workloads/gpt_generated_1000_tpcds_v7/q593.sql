WITH filtered AS (
    SELECT
        c.c_salutation AS salutation,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.c_email_address AS email_address,
        ws.ws_order_number AS order_number,
        ws.ws_net_paid_inc_ship AS ws_net_paid_inc_ship,
        ws.ws_net_profit AS ws_net_profit,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_ship_date_sk BETWEEN 2451400 AND 2451800
      AND regexp_like(c.c_email_address, '@.*\\.com$')
      AND c.c_last_name LIKE 'S%'
      AND c.c_salutation IN ('Mr.', 'Mrs.', 'Ms.', 'Dr.')
)
SELECT
    salutation,
    email_domain,
    COUNT(DISTINCT order_number) AS distinct_orders,
    SUM(ws_net_paid_inc_ship) AS total_net_paid_inc_ship,
    SUM(ws_net_profit) AS total_net_profit,
    MIN(concat(first_name, ' ', last_name)) AS sample_full_name
FROM filtered
GROUP BY salutation, email_domain
HAVING COUNT(*) > 5
ORDER BY total_net_profit DESC
LIMIT 20
