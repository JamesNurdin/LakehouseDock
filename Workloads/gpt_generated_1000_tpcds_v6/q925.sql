WITH promo_sales AS (
    SELECT
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 1000000 THEN 'High'
            WHEN SUM(ss.ss_ext_sales_price) > 500000  THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(p.p_promo_name, '^.*[A-Za-z]{3}[0-9]{2}.*$')
      AND p.p_channel_email LIKE 'Y'
    GROUP BY p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d+)', 1)
),
call_center_cities AS (
    SELECT DISTINCT cc.cc_city
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_city LIKE 'A%'
)
SELECT
    ps.p_promo_name,
    ps.promo_number,
    concat(ps.p_promo_name, '-', ps.promo_number) AS promo_label,
    ps.total_sales,
    ps.avg_profit,
    ps.sales_category,
    CASE
        WHEN cc.cc_city IS NOT NULL THEN 'In_A_City'
        ELSE 'Other_City'
    END AS city_flag
FROM promo_sales ps
LEFT JOIN call_center_cities cc ON TRUE
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    JOIN date_dim wd ON wp.wp_access_date_sk = wd.d_date_sk
    WHERE wd.d_year = 2001
      AND wp.wp_url LIKE '%product%'
      AND regexp_like(wp.wp_url, '^https?://')
      AND wp.wp_type LIKE 'content%'
      AND wp.wp_image_count > 0
)
ORDER BY ps.total_sales DESC
LIMIT 100
