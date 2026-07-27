WITH filtered AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_ext_tax,
        ws.ws_net_paid_inc_ship,
        wp.wp_type,
        wp.wp_rec_start_date,
        wp.wp_max_ad_count
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
      AND wp.wp_max_ad_count >= 2
      AND ws.ws_ext_tax > 20
)
SELECT
    wp_type,
    DATE_TRUNC('month', wp_rec_start_date) AS month,
    COUNT(*) AS sales_cnt,
    SUM(ws_net_paid_inc_ship) AS total_net_paid,
    AVG(ws_ext_tax) AS avg_tax,
    MIN(ws_net_paid_inc_ship) AS min_net_paid,
    MAX(ws_net_paid_inc_ship) AS max_net_paid
FROM filtered
GROUP BY wp_type, DATE_TRUNC('month', wp_rec_start_date)
HAVING SUM(ws_net_paid_inc_ship) > 20000
ORDER BY total_net_paid DESC
LIMIT 100
