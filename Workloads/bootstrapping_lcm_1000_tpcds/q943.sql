SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date   AS promo_end_date,
    d_store_closed.d_date AS store_closed_date,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(cd.cd_purchase_estimate)    AS avg_purchase_estimate,
    SUM(p.p_cost)                   AS total_promo_cost,
    COUNT(DISTINCT CASE WHEN cd.cd_gender = 'M' THEN c.c_customer_id END) AS male_customers,
    COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN c.c_customer_id END) AS female_customers,
    MIN(d_sales.d_date) AS earliest_customer_sales_date,
    MAX(d_sales.d_date) AS latest_customer_sales_date
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk <= d_store_closed.d_date_sk
   AND p.p_end_date_sk   >= d_store_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk   = d_promo_end.d_date_sk
JOIN date_dim d_sales
    ON d_sales.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
JOIN customer c
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_shipto
    ON c.c_first_shipto_date_sk = d_shipto.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE d_shipto.d_dow = d_promo_start.d_dow
  AND d_review.d_weekend = 'N'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_store_closed.d_date
ORDER BY num_customers DESC
LIMIT 100
