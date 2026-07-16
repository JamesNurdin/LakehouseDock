SELECT
    cd.cd_gender,
    cd.cd_education_status,
    s.s_state,
    d_closure.d_year AS closure_year,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    AVG(wp.wp_max_ad_count) AS avg_max_ads,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_viewed,
    MIN(d_create.d_date) AS earliest_page_creation,
    MAX(d_access.d_date) AS latest_page_access,
    SUM(CASE WHEN d_create.d_year = d_closure.d_year THEN 1 ELSE 0 END) AS pages_created_in_closure_year,
    AVG(DATE_DIFF('day', d_ship.d_date, d_review.d_date)) AS avg_days_between_ship_and_review
FROM store s
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_closure.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_create
    ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE cd.cd_credit_rating IN ('A', 'B', 'C')
  AND s.s_state IS NOT NULL
GROUP BY cd.cd_gender, cd.cd_education_status, s.s_state, d_closure.d_year
HAVING COUNT(DISTINCT c.c_customer_sk) >= 5
ORDER BY d_closure.d_year DESC, total_image_count DESC
LIMIT 100
