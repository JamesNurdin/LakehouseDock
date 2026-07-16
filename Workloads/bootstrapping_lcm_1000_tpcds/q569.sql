SELECT
    s.s_store_id,
    s.s_city,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    t_ret.t_hour,
    CASE
        WHEN c_ref.c_birth_year < c_ret.c_birth_year THEN 'refunded_younger'
        WHEN c_ref.c_birth_year > c_ret.c_birth_year THEN 'refunded_older'
        ELSE 'same_birth_year'
    END AS age_relation,
    d_ship.d_year AS shipto_year,
    d_sales.d_year AS first_sales_year,
    d_rev.d_year AS last_review_year,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_fee), 0) AS return_to_fee_ratio
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_ship
    ON c_ref.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c_ref.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_rev
    ON c_ret.c_last_review_date = d_rev.d_date_sk
WHERE cr.cr_return_quantity > 1
  AND cr.cr_return_amount > 100
  AND t_ret.t_meal_time = 'Dinner'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    t_ret.t_hour,
    CASE
        WHEN c_ref.c_birth_year < c_ret.c_birth_year THEN 'refunded_younger'
        WHEN c_ref.c_birth_year > c_ret.c_birth_year THEN 'refunded_older'
        ELSE 'same_birth_year'
    END,
    d_ship.d_year,
    d_sales.d_year,
    d_rev.d_year
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
