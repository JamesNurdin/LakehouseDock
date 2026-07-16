SELECT
    s.s_store_id,
    s.s_city,
    d_date.d_year AS store_closed_year,
    cd.cd_gender,
    CASE
        WHEN cd.cd_credit_rating = 'A' THEN 'High'
        WHEN cd.cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END AS credit_rating_category,
    d_shipto.d_year AS first_shipto_year,
    d_sales.d_year AS first_sales_year,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    COUNT(*) AS total_page_views,
    AVG(wp.wp_char_count) AS avg_char_count,
    SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
    MIN(d_access.d_date) AS earliest_access_date,
    MAX(d_date.d_date) AS latest_creation_date
FROM
    store s
    INNER JOIN date_dim d_date
        ON s.s_closed_date_sk = d_date.d_date_sk
    INNER JOIN web_page wp
        ON wp.wp_creation_date_sk = d_date.d_date_sk
    INNER JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    INNER JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN date_dim d_shipto
        ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
    INNER JOIN date_dim d_sales
        ON c.c_first_sales_date_sk = d_sales.d_date_sk
WHERE
    d_date.d_year >= 2020
GROUP BY
    s.s_store_id,
    s.s_city,
    d_date.d_year,
    cd.cd_gender,
    cd.cd_credit_rating,
    d_shipto.d_year,
    d_sales.d_year
HAVING
    COUNT(*) > 10
