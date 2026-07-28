WITH sales_recent AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)
SELECT
    sr.ws_web_site_sk,
    s.web_name,
    COUNT(DISTINCT sr.ws_order_number) AS orders,
    SUM(sr.ws_net_paid) AS total_net_paid,
    AVG(sr.ws_quantity) AS avg_quantity,
    regexp_extract(s.web_mkt_desc, '(\\w+) negotiations', 1) AS market_keyword,
    CONCAT(s.web_city, ', ', s.web_state) AS location,
    CASE
        WHEN regexp_like(s.web_name, '^.*shop.*$') THEN 'Shop'
        ELSE 'Other'
    END AS site_type,
    COUNT(*) FILTER (WHERE LOWER(p.wp_url) LIKE '%example.com%') AS example_url_hits
FROM sales_recent sr
JOIN web_site s ON sr.ws_web_site_sk = s.web_site_sk
JOIN web_page p ON sr.ws_web_page_sk = p.wp_web_page_sk
GROUP BY
    sr.ws_web_site_sk,
    s.web_name,
    s.web_mkt_desc,
    s.web_city,
    s.web_state
HAVING SUM(sr.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
