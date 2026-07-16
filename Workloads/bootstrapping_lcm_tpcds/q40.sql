SELECT
    s.s_market_desc,
    w.web_name,
    cd.cd_gender,
    cd.cd_marital_status,
    (cd.cd_gender || '_' || cd.cd_marital_status) AS gender_marital,
    d_shipto.d_year AS ship_year,
    d_sales.d_month_seq AS sales_month_seq,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_count,
    MIN(d_review.d_date) AS earliest_review_date,
    MAX(d_review.d_date) AS latest_review_date,
    COUNT(*) FILTER (WHERE c.c_birth_country = 'USA') AS usa_customers
FROM
    customer c
JOIN
    customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    date_dim d_shipto
        ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN
    date_dim d_sales
        ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN
    date_dim d_review
        ON c.c_last_review_date = d_review.d_date_sk
JOIN
    store s
        ON s.s_closed_date_sk = d_review.d_date_sk
JOIN
    date_dim d_store_close
        ON s.s_closed_date_sk = d_store_close.d_date_sk
JOIN
    web_site w
        ON w.web_open_date_sk = d_store_close.d_date_sk
JOIN
    date_dim d_web_open
        ON w.web_open_date_sk = d_web_open.d_date_sk
JOIN
    date_dim d_web_close
        ON w.web_close_date_sk = d_web_close.d_date_sk
WHERE
    s.s_state = 'CA'
    AND w.web_state = 'CA'
    AND d_shipto.d_year BETWEEN 2015 AND 2020
GROUP BY
    s.s_market_desc,
    w.web_name,
    cd.cd_gender,
    cd.cd_marital_status,
    d_shipto.d_year,
    d_sales.d_month_seq
HAVING
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY
    total_purchase_estimate DESC
LIMIT 100
