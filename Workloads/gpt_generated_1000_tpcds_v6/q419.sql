WITH filtered AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_quantity,
        wp.wp_url,
        wp.wp_type,
        wp.wp_rec_start_date,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        regexp_extract(wp.wp_url, '/([^/]+)$', 1) AS last_path
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_rec_start_date < DATE '2001-01-01'
      AND regexp_like(wp.wp_url, '\\.com')
      AND wp.wp_type LIKE 'C%'
)
SELECT
    domain,
    wp_type,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_quantity) AS avg_quantity,
    CONCAT('Domain: ', domain) AS label
FROM filtered
GROUP BY domain, wp_type, CONCAT('Domain: ', domain)
HAVING SUM(ws_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
