WITH site_sales AS (
    SELECT
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_mkt_class,
    ss.total_net_paid,
    ss.sales_cnt,
    CASE
        WHEN ss.total_net_paid > 100000 THEN 'High'
        WHEN ss.total_net_paid > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category,
    regexp_extract(ws.web_mkt_class, '^(\\w+)', 1) AS mkt_class_first_word,
    concat(ws.web_city, ', ', ws.web_state) AS location,
    (
        SELECT avg(ws2.ws_ext_discount_amt)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = ws.web_site_sk
    ) AS avg_discount_amt
FROM web_site ws
JOIN site_sales ss ON ss.ws_web_site_sk = ws.web_site_sk
WHERE regexp_like(ws.web_mkt_class, '\\bNew\\b')
  AND ws.web_site_id LIKE 'AAAA%'
  AND substr(ws.web_city, 1, 1) = 'S'
ORDER BY ss.total_net_paid DESC
LIMIT 100
