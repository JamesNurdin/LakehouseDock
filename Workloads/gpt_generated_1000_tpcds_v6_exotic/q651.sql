WITH url_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity,
        d.d_year,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        CASE
            WHEN wp.wp_url LIKE '%sale%' THEN 'Sale'
            WHEN wp.wp_url LIKE '%clearance%' THEN 'Clearance'
            ELSE 'Other'
        END AS url_category,
        CONCAT('Year-', CAST(d.d_year AS VARCHAR)) AS year_label
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*example\\.com/.*')
      AND wp.wp_url LIKE '%product%'
)
SELECT
    d_year,
    year_label,
    domain,
    url_category,
    COUNT(DISTINCT ws_order_number) AS num_orders,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(CASE WHEN ws_net_profit > 0 THEN ws_net_profit ELSE 0 END) AS positive_profit_sum,
    AVG(ws_quantity) AS avg_quantity,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = url_sales.d_year
    ) AS yearly_avg_net_paid
FROM url_sales
GROUP BY d_year, year_label, domain, url_category
HAVING COUNT(*) > 20
ORDER BY total_net_paid DESC
LIMIT 100
