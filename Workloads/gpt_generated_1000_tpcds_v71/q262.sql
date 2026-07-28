WITH filtered_pages AS (
    SELECT wp.wp_web_page_sk,
           wp.wp_customer_sk,
           wp.wp_link_count,
           wp.wp_char_count,
           wp.wp_image_count,
           wp.wp_type,
           wp.wp_access_date_sk,
           wp.wp_rec_start_date,
           wp.wp_rec_end_date
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_link_count > 10
      AND wp.wp_access_date_sk BETWEEN 2452600 AND 2452650
      AND wp.wp_rec_start_date >= DATE '2023-01-01'
      AND wp.wp_rec_end_date <= DATE '2023-12-31'
      AND wp.wp_type = 'article'
),
high_link_counts AS (
    SELECT wp.wp_customer_sk AS customer_sk,
           COUNT(*) AS high_link_pages
    FROM web_page wp
    WHERE wp.wp_link_count > 20
    GROUP BY wp.wp_customer_sk
)
SELECT
    c.c_customer_id,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    COUNT(DISTINCT fp.wp_web_page_sk) AS page_count,
    SUM(fp.wp_link_count) AS total_links,
    AVG(fp.wp_char_count) AS avg_char_count,
    MAX(fp.wp_image_count) AS max_images,
    CASE
        WHEN cd.cd_dep_count = 0 THEN 'No dependents'
        WHEN cd.cd_dep_count <= 2 THEN 'Few dependents'
        ELSE 'Many dependents'
    END AS dep_category,
    COALESCE(hlc.high_link_pages, 0) AS high_link_pages
FROM filtered_pages fp
JOIN customer c ON fp.wp_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN high_link_counts hlc ON c.c_customer_sk = hlc.customer_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1985
  AND cd.cd_credit_rating IN ('Low Risk', 'Good')
  AND hd.hd_income_band_sk = 3
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_last_review_date >= 2452400
GROUP BY
    c.c_customer_id,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    CASE
        WHEN cd.cd_dep_count = 0 THEN 'No dependents'
        WHEN cd.cd_dep_count <= 2 THEN 'Few dependents'
        ELSE 'Many dependents'
    END,
    COALESCE(hlc.high_link_pages, 0)
ORDER BY total_links DESC
LIMIT 100
