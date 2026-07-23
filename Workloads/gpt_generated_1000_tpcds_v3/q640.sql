WITH filtered_customers AS (
    SELECT DISTINCT c.c_customer_sk,
           regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM customer c
    WHERE c.c_email_address LIKE '%@example.com'
)
SELECT
    ws.ws_web_site_sk,
    web_site.web_site_id,
    web_site.web_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    fc.email_domain
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
JOIN filtered_customers fc ON ws.ws_bill_customer_sk = fc.c_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE
    regexp_like(wp.wp_url, '(?i)sale')
    AND d.d_year = 2001
    AND EXISTS (
        SELECT 1
        FROM store_sales ss
        JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
        WHERE ss.ss_customer_sk = ws.ws_bill_customer_sk
          AND d2.d_year = d.d_year
          AND ss.ss_net_paid > 500
    )
GROUP BY
    ws.ws_web_site_sk,
    web_site.web_site_id,
    web_site.web_name,
    fc.email_domain
HAVING
    SUM(ws.ws_net_profit) > 5000
    AND COUNT(DISTINCT ws.ws_bill_customer_sk) >= 5
ORDER BY total_net_profit DESC
LIMIT 100
