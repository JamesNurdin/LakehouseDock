WITH page_sales AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid
    FROM tpcds.web_page wp
    JOIN tpcds.web_sales ws
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]*example\\.com')
      AND wp.wp_type LIKE 'C%'
)
SELECT
    ps.wp_type,
    ps.domain,
    substring(ps.wp_url, 1, 30) AS url_prefix,
    COUNT(DISTINCT ps.ws_order_number) AS order_cnt,
    SUM(ps.ws_net_profit) AS total_profit,
    AVG(ps.ws_net_paid) AS avg_net_paid,
    CONCAT('Domain: ', ps.domain) AS label
FROM page_sales ps
WHERE EXISTS (
    SELECT 1
    FROM tpcds.web_sales ws2
    WHERE ws2.ws_web_page_sk = ps.wp_web_page_sk
      AND ws2.ws_ext_discount_amt > 500
)
  AND ps.ws_net_profit > (
    SELECT AVG(ws3.ws_net_profit)
    FROM tpcds.web_sales ws3
)
GROUP BY ps.wp_type, ps.domain, ps.wp_url
ORDER BY total_profit DESC
LIMIT 10
