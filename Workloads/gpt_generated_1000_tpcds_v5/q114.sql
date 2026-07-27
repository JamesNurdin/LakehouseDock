WITH sales_page AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_coupon_amt,
        ws.ws_net_profit,
        ws.ws_order_number,
        wp.wp_type,
        wp.wp_url,
        wp.wp_autogen_flag,
        wp.wp_char_count
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND wp.wp_url LIKE 'http%'
)
SELECT
    ws_site.web_site_id,
    ws_site.web_mkt_class,
    ws_site.web_class,
    CONCAT('Site ', ws_site.web_site_id) AS site_label,
    regexp_extract(wp_url, '://([^/]+)', 1) AS domain,
    wp_type,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws_order_number) AS distinct_orders
FROM sales_page sp
JOIN tpcds.web_site ws_site
  ON sp.ws_web_site_sk = ws_site.web_site_sk
WHERE regexp_like(ws_site.web_class, '^New.*homes')
  AND ws_site.web_mkt_class LIKE '%Broad%'
GROUP BY
    ws_site.web_site_id,
    ws_site.web_mkt_class,
    ws_site.web_class,
    CONCAT('Site ', ws_site.web_site_id),
    regexp_extract(wp_url, '://([^/]+)', 1),
    wp_type
ORDER BY total_net_paid DESC
LIMIT 100
