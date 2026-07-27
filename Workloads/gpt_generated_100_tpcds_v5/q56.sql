WITH promo_filtered AS (
    SELECT p.p_promo_sk,
           p.p_promo_id,
           p.p_cost,
           p.p_start_date_sk,
           p.p_end_date_sk,
           p.p_channel_radio,
           p.p_discount_active
    FROM promotion p
    WHERE p.p_channel_radio = 'N'
      AND p.p_discount_active = 'Y'
),
wp_filtered AS (
    SELECT wp.wp_web_page_sk,
           wp.wp_url,
           wp.wp_image_count,
           wp.wp_max_ad_count,
           wp.wp_creation_date_sk,
           wp.wp_access_date_sk,
           wp.wp_char_count
    FROM web_page wp
    WHERE wp.wp_url = 'http://www.foo.com'
      AND wp.wp_image_count >= 2
)
SELECT
    cp.cp_department,
    d_year.d_year,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_pages,
    SUM(pf.p_cost) AS total_promo_cost,
    AVG(wf.wp_char_count) AS avg_char_count,
    CASE
        WHEN SUM(pf.p_cost) > 1000 THEN 'HighSpend'
        ELSE 'LowSpend'
    END AS spend_category,
    MAX(d_end.d_date) AS latest_end_date
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN promo_filtered pf
    ON pf.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_year
    ON pf.p_start_date_sk = d_year.d_date_sk
JOIN wp_filtered wf
    ON wf.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_wp_access
    ON wf.wp_access_date_sk = d_wp_access.d_date_sk
WHERE cp.cp_type = 'Catalog'
  AND cp.cp_catalog_page_number > 10
  AND d_year.d_year = 2001
  AND d_wp_access.d_month_seq BETWEEN 1 AND 12
GROUP BY cp.cp_department, d_year.d_year
ORDER BY total_promo_cost DESC
LIMIT 100
