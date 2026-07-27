WITH filtered_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        d.d_year,
        ws.ws_bill_customer_sk,
        ws.ws_order_number,
        c.c_last_name,
        c.c_email_address,
        web_site.web_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE d.d_year = 2002
      AND web_site.web_name LIKE '%Online%'
      AND regexp_like(c.c_email_address, '@example\\.com$')
)
SELECT
    ws_web_site_sk,
    ws_sold_date_sk,
    d_year,
    web_name,
    CASE WHEN regexp_like(c_last_name, '^A') THEN 'A-Name' ELSE 'Other' END AS last_name_group,
    regexp_extract(web_name, '([A-Za-z]+)\\s+Online', 1) AS extracted_word,
    concat('Site-', web_name) AS site_label,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS order_count
FROM filtered_sales
GROUP BY
    ws_web_site_sk,
    ws_sold_date_sk,
    d_year,
    web_name,
    CASE WHEN regexp_like(c_last_name, '^A') THEN 'A-Name' ELSE 'Other' END,
    regexp_extract(web_name, '([A-Za-z]+)\\s+Online', 1),
    concat('Site-', web_name)
ORDER BY total_profit DESC
LIMIT 10
