SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d.d_year,
    d.d_quarter_name,
    d.d_fy_quarter_seq,
    cd.cd_gender,
    cd.cd_education_status,
    cd.cd_credit_rating,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 1 ELSE 0 END) AS excellent_credit_customers,
    AVG(wp.wp_image_count) AS avg_image_count,
    AVG(wp.wp_link_count) AS avg_link_count,
    MIN(wp.wp_url) AS sample_url
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON s.s_store_sk = ss.ss_store_sk
    AND s.s_closed_date_sk = d.d_date_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = ss.ss_cdemo_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
    AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND cd.cd_gender = 'F'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d.d_year,
    d.d_quarter_name,
    d.d_fy_quarter_seq,
    cd.cd_gender,
    cd.cd_education_status,
    cd.cd_credit_rating
ORDER BY total_profit DESC
LIMIT 100
