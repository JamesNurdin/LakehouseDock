SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    dr_return.d_date AS return_date,
    EXTRACT(year FROM dr_return.d_date) AS return_year,
    EXTRACT(month FROM dr_return.d_date) AS return_month,
    c_ret.c_customer_id AS returning_customer_id,
    c_ret.c_first_name AS returning_first_name,
    c_ret.c_last_name AS returning_last_name,
    c_ret.c_birth_country AS returning_birth_country,
    c_ret.c_birth_year AS returning_birth_year,
    ca_ret.ca_city AS returning_address_city,
    ca_ret.ca_state AS returning_address_state,
    ca_curr_ret.ca_city AS returning_current_city,
    ca_curr_ret.ca_state AS returning_current_state,
    c_ref.c_customer_id AS refunded_customer_id,
    c_ref.c_first_name AS refunded_first_name,
    c_ref.c_last_name AS refunded_last_name,
    ca_ref.ca_city AS refunded_address_city,
    ca_ref.ca_state AS refunded_address_state,
    ca_curr_ref.ca_city AS refunded_current_city,
    ca_curr_ref.ca_state AS refunded_current_state,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_return_ship_cost,
    date_diff('day', dr_shipto.d_date, dr_return.d_date) AS days_since_first_shipto,
    date_diff('day', dr_sales.d_date, dr_return.d_date) AS days_since_first_sales,
    date_diff('day', dr_review.d_date, dr_return.d_date) AS days_since_last_review,
    (EXTRACT(year FROM dr_return.d_date) - c_ret.c_birth_year) AS returning_customer_age_at_return,
    SUM(cr.cr_return_amount) OVER (
        PARTITION BY s.s_store_id,
                     EXTRACT(year FROM dr_return.d_date),
                     EXTRACT(month FROM dr_return.d_date)
    ) AS store_monthly_total_return_amount,
    SUM(cr.cr_net_loss) OVER (
        PARTITION BY s.s_store_id,
                     EXTRACT(year FROM dr_return.d_date),
                     EXTRACT(month FROM dr_return.d_date)
    ) AS store_monthly_total_net_loss,
    COUNT(*) OVER (
        PARTITION BY s.s_store_id,
                     EXTRACT(year FROM dr_return.d_date),
                     EXTRACT(month FROM dr_return.d_date)
    ) AS store_monthly_return_count
FROM catalog_returns cr
JOIN date_dim dr_return
    ON cr.cr_returned_date_sk = dr_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr_return.d_date_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_curr_ret
    ON c_ret.c_current_addr_sk = ca_curr_ret.ca_address_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_curr_ref
    ON c_ref.c_current_addr_sk = ca_curr_ref.ca_address_sk
JOIN date_dim dr_shipto
    ON c_ret.c_first_shipto_date_sk = dr_shipto.d_date_sk
JOIN date_dim dr_sales
    ON c_ret.c_first_sales_date_sk = dr_sales.d_date_sk
JOIN date_dim dr_review
    ON c_ret.c_last_review_date = dr_review.d_date_sk
WHERE dr_return.d_year = 2022
  AND s.s_country = 'United States'
ORDER BY store_monthly_total_net_loss DESC
LIMIT 100
