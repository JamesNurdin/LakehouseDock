SELECT
    c.c_customer_id,
    cd.cd_gender,
    d_ship.d_year AS ship_year,
    d_sales.d_month_seq AS sales_month_seq,
    d_review.d_week_seq AS review_week_seq,
    s.s_state,
    s.s_city,
    p.p_promo_name,
    COUNT(*) AS order_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM customer c
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ship.d_date_sk
JOIN date_dim d_pend
    ON p.p_end_date_sk = d_pend.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_pend.d_date_sk
WHERE
    cd.cd_gender = 'F'
    AND s.s_state IN ('CA', 'NY')
    AND p.p_discount_active = 'Y'
    AND d_ship.d_year BETWEEN 2015 AND 2020
GROUP BY
    c.c_customer_id,
    cd.cd_gender,
    d_ship.d_year,
    d_sales.d_month_seq,
    d_review.d_week_seq,
    s.s_state,
    s.s_city,
    p.p_promo_name
HAVING COUNT(*) > 5
ORDER BY total_promo_cost DESC
LIMIT 100
