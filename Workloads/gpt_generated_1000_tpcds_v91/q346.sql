WITH customer_email_parts_agg AS (
    SELECT
        c.c_customer_sk,
        array_agg(DISTINCT part) AS email_parts
    FROM customer c
    CROSS JOIN UNNEST(split(c.c_email_address, '@')) AS t(part)
    GROUP BY c.c_customer_sk
)
SELECT
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    c.c_customer_sk,
    ds.d_year,
    substring(c.c_email_address, 1, strpos(c.c_email_address, '@') - 1) AS email_local_part,
    regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    cep.email_parts
FROM web_sales ws
JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_email_parts_agg cep ON c.c_customer_sk = cep.c_customer_sk
WHERE regexp_like(c.c_email_address, '@[^@]+\\.com$')
  AND c.c_first_name LIKE 'A%'
  AND ds.d_date >= DATE '2000-01-01'
  AND ds.d_date < DATE '2001-01-01'
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
    )
GROUP BY
    c.c_customer_sk,
    ds.d_year,
    concat(c.c_first_name, ' ', c.c_last_name),
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END,
    substring(c.c_email_address, 1, strpos(c.c_email_address, '@') - 1),
    regexp_extract(c.c_email_address, '@([^@]+)$', 1),
    cep.email_parts
ORDER BY total_profit DESC
LIMIT 100
