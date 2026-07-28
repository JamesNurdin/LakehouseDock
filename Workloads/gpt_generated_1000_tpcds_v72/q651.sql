WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        wp.wp_url,
        wp.wp_web_page_id,
        wsite.web_site_id,
        d.d_year
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(wp.wp_url, '/product/P[0-9]{4}')
      AND wsite.web_manager LIKE 'J%'
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_promo_sk = ws.ws_promo_sk
            AND regexp_like(p.p_promo_name, 'Discount')
      )
)
SELECT
    fs.wp_web_page_id,
    fs.web_site_id,
    fs.d_year,
    COUNT(*) AS orders,
    SUM(fs.ws_net_paid) AS total_net_paid,
    AVG(fs.ws_ext_discount_amt) AS avg_discount,
    regexp_extract(fs.wp_url, 'P([0-9]{4})', 1) AS product_code,
    CONCAT('URL_', SUBSTRING(fs.wp_url FROM 1 FOR 20)) AS url_prefix
FROM filtered_sales fs
GROUP BY
    fs.wp_web_page_id,
    fs.web_site_id,
    fs.d_year,
    fs.wp_url
HAVING SUM(fs.ws_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
