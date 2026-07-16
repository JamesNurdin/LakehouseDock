SELECT
    s.s_city AS store_city,
    d_sales.d_year AS sales_year,
    cd.cd_gender AS gender,
    CASE WHEN cd.cd_dep_count > 5 THEN 'HighDep' ELSE 'LowDep' END AS dep_category,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    COUNT(wp.wp_web_page_id) AS total_web_pages,
    SUM(wp.wp_image_count) AS total_images,
    AVG(cd.cd_dep_count) AS avg_dependent_count,
    SUM(CASE WHEN wp.wp_type = 'home' THEN 1 ELSE 0 END) AS home_page_visits,
    MIN(c.c_birth_year) AS min_birth_year,
    MAX(c.c_birth_year) AS max_birth_year
FROM customer c
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
WHERE s.s_state = 'CA'
  AND d_sales.d_year BETWEEN 2015 AND 2020
  AND cd.cd_marital_status = 'M'
  AND d_wp_create.d_year = d_sales.d_year
GROUP BY
    s.s_city,
    d_sales.d_year,
    cd.cd_gender,
    CASE WHEN cd.cd_dep_count > 5 THEN 'HighDep' ELSE 'LowDep' END
HAVING COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY
    s.s_city,
    d_sales.d_year,
    cd.cd_gender
LIMIT 100
