SELECT
    s.s_store_id,
    s.s_store_name,
    d_closed.d_date AS store_closed_date,
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    p.p_cost,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(d_first_sales.d_date) AS earliest_customer_first_sales,
    MAX(d_last_review.d_date) AS latest_customer_last_review
FROM store s
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_closed.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_start.d_date_sk
JOIN date_dim d_first_sales
    ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN date_dim d_first_shipto
    ON c.c_first_shipto_date_sk = d_first_shipto.d_date_sk
JOIN date_dim d_last_review
    ON c.c_last_review_date = d_last_review.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE p.p_cost > 5000
  AND s.s_state = 'CA'
  AND cd.cd_credit_rating IN ('A', 'B')
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_closed.d_date,
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_date,
    d_end.d_date,
    p.p_cost
HAVING COUNT(DISTINCT c.c_customer_id) >= 10
ORDER BY s.s_store_id, p.p_promo_id
