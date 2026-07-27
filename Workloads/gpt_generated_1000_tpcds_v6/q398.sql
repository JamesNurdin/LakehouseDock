WITH
  sales_agg AS (
    SELECT
      d.d_year,
      p.p_promo_name,
      MAX(COALESCE(wp.wp_type, 'none')) AS wp_type_used,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND d.d_month_seq >= 1200
      AND ss.ss_ext_list_price > 2000
      AND hd.hd_vehicle_count >= 0
      AND p.p_discount_active = 'Y'
      AND wp.wp_type IN ('ad', 'welcome')
      AND hd.hd_income_band_sk IS NOT NULL
    GROUP BY d.d_year, p.p_promo_name
  ),
  page_agg AS (
    SELECT
      d.d_year,
      wp.wp_type,
      COUNT(DISTINCT wp.wp_web_page_id) AS page_cnt
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND wp.wp_type IS NOT NULL
      AND wp.wp_char_count > 1000
      AND wp.wp_image_count >= 0
      AND wp.wp_max_ad_count > 0
    GROUP BY d.d_year, wp.wp_type
  )
SELECT
  u.year,
  AVG(u.metric) AS avg_metric
FROM (
  SELECT
    sa.d_year AS year,
    sa.p_promo_name AS category,
    sa.total_sales AS metric
  FROM sales_agg sa

  UNION ALL

  SELECT
    pa.d_year AS year,
    pa.wp_type AS category,
    CAST(pa.page_cnt AS decimal(12,2)) AS metric
  FROM page_agg pa
) u
GROUP BY u.year
ORDER BY avg_metric DESC
LIMIT 100
