SELECT
    ROW_NUMBER() OVER (ORDER BY d.d_date DESC) AS rank,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    cd.cd_gender,
    cd.cd_education_status,
    s.s_store_name,
    s.s_state,
    s.s_city,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
FROM store s
JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_access_date_sk = d.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
   AND c.c_first_shipto_date_sk = d.d_date_sk
   AND c.c_first_sales_date_sk = d.d_date_sk
   AND c.c_last_review_date = d.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
ORDER BY d.d_date DESC
LIMIT 100
