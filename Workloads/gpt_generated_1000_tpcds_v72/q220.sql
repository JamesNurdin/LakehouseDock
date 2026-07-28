WITH sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_promo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_qty,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 1
      AND ss_sales_price > 10.00
    GROUP BY ss_sold_date_sk, ss_promo_sk
)
SELECT
    d.d_date,
    p.p_promo_name,
    wp.wp_type,
    SUM(sa.total_sales) AS sum_sales,
    AVG(sa.total_sales) AS avg_sales,
    SUM(sa.total_qty) AS sum_qty,
    COUNT(DISTINCT sa.ss_sold_date_sk) AS distinct_days,
    MIN(sa.total_sales) AS min_sales,
    MAX(sa.total_sales) AS max_sales
FROM sales_agg sa
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE p.p_channel_demo = 'N'
  AND p.p_channel_event = 'N'
  AND p.p_promo_sk IN (5, 7, 13)
  AND d.d_year = 2002
  AND d.d_current_day = 'N'
  AND wp.wp_image_count BETWEEN 2 AND 5
  AND wp.wp_max_ad_count <= 3
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = p.p_promo_sk
          AND p2.p_cost > 500.00
    )
GROUP BY ROLLUP (d.d_date, p.p_promo_name, wp.wp_type)
ORDER BY d.d_date ASC NULLS LAST, p.p_promo_name ASC NULLS LAST, wp.wp_type ASC NULLS LAST
LIMIT 100
