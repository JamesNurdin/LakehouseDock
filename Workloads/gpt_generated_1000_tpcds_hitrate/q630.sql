WITH page_sales AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_web_page_sk, ws.ws_web_site_sk, ws.ws_sold_date_sk
)
SELECT
    wp.wp_web_page_id,
    wp.wp_url,
    CASE
        WHEN regexp_like(wp.wp_url, '^https?://.*sale.*') THEN 'SalePage'
        ELSE 'OtherPage'
    END AS page_type,
    CONCAT(wsite.web_name, ' - ', wp.wp_type) AS site_page_label,
    ws.total_net_paid,
    CASE
        WHEN ws.total_net_paid > 10000 THEN 'High'
        WHEN ws.total_net_paid > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category,
    (SELECT AVG(ws2.ws_net_paid_inc_tax)
     FROM tpcds.web_sales ws2
     WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk) AS avg_daily_net,
    lt.segment,
    ws.sales_cnt
FROM page_sales ws
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN LATERAL (
    SELECT regexp_extract(wp.wp_url, '/([^/]+)\\.html$', 1) AS segment
) AS lt ON TRUE
WHERE wp.wp_type LIKE 'Content%'
  AND wsite.web_class LIKE '%Online%'
  AND EXISTS (
        SELECT 1 FROM tpcds.store_sales ss
        WHERE ss.ss_sold_date_sk = ws.ws_sold_date_sk AND ss.ss_quantity > 0
    )
ORDER BY ws.total_net_paid DESC
LIMIT 100
