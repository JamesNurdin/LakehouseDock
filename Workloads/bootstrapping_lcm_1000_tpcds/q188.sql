SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    (cd_ret.cd_gender || '_' || cd_ret.cd_marital_status) AS gender_marital,
    cd_curr_ret.cd_gender AS returning_current_gender,
    cd_curr_ref.cd_gender AS refunded_current_gender,
    CASE WHEN cr.cr_return_amount > 200 THEN 'High' ELSE 'Low' END AS return_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date,
    MIN(d_sales.d_date) AS earliest_customer_first_sales_date,
    MAX(d_ship.d_date) AS latest_customer_first_shipto_date
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_curr_ret
    ON c_ret.c_current_cdemo_sk = cd_curr_ret.cd_demo_sk
JOIN customer_demographics cd_curr_ref
    ON c_ref.c_current_cdemo_sk = cd_curr_ref.cd_demo_sk
JOIN date_dim d_sales
    ON c_ret.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON c_ret.c_first_shipto_date_sk = d_ship.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    (cd_ret.cd_gender || '_' || cd_ret.cd_marital_status),
    cd_curr_ret.cd_gender,
    cd_curr_ref.cd_gender,
    CASE WHEN cr.cr_return_amount > 200 THEN 'High' ELSE 'Low' END
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY total_net_loss DESC
LIMIT 100
