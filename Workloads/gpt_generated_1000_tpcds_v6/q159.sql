WITH filtered_promos AS (
    SELECT p_promo_sk,
           p_promo_name,
           p_channel_email
    FROM promotion
    WHERE p_channel_email LIKE 'Y'
      AND regexp_like(p_promo_name, 'Discount')
)
SELECT
    fp.p_promo_name,
    w.w_city,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    CONCAT('City ', w.w_city) AS city_label,
    SUBSTR(w.w_street_name, 1, 5) AS street_prefix
FROM web_sales ws
JOIN filtered_promos fp ON ws.ws_promo_sk = fp.p_promo_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2022
  AND w.w_city LIKE 'A%'
GROUP BY
    fp.p_promo_name,
    w.w_city,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1),
    CONCAT('City ', w.w_city),
    SUBSTR(w.w_street_name, 1, 5)
ORDER BY total_profit DESC
LIMIT 100
