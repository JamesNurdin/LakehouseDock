SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    web_site.web_name,
    regexp_extract(web_site.web_name, '(\\w+)') AS first_word,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
WHERE regexp_like(web_site.web_name, 'Shop')
  AND regexp_like(c.c_email_address, '@example\\.com$')
  AND c.c_customer_sk IN (
        SELECT sr_customer_sk
        FROM store_returns
        WHERE sr_return_amt > 100
    )
GROUP BY
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name),
    web_site.web_name,
    regexp_extract(web_site.web_name, '(\\w+)')
ORDER BY total_net_paid DESC
LIMIT 100
