WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 5000
),
joined_data AS (
    SELECT
        ws.ws_web_site_sk,
        d.d_year,
        ws.ws_net_profit,
        ws.ws_order_number,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
    FROM filtered_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.*@.*\\.com$')
      AND c.c_first_name LIKE 'A%'
)
SELECT
    web.web_name,
    jd.d_year,
    COUNT(DISTINCT jd.ws_order_number) AS orders,
    SUM(jd.ws_net_profit) AS total_profit,
    any_value(CONCAT(jd.c_first_name, ' ', jd.c_last_name)) AS sample_customer,
    any_value(REGEXP_EXTRACT(jd.c_email_address, '@([^.]*)\\.', 1)) AS email_domain
FROM joined_data jd
JOIN web_site web ON jd.ws_web_site_sk = web.web_site_sk
WHERE web.web_name LIKE '%Shop%'
GROUP BY
    web.web_name,
    jd.d_year
HAVING SUM(jd.ws_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 20
