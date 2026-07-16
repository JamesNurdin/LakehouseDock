SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    (cr.cr_return_quantity * cr.cr_return_amount) AS total_return_value,
    cr.cr_net_loss,
    d_return.d_date AS return_date,
    d_return.d_year AS return_year,
    d_return.d_quarter_name AS return_quarter,
    cust_refunded.c_customer_id AS refunded_customer_id,
    cust_refunded.c_email_address AS refunded_email,
    cust_refunded.c_first_name AS refunded_first_name,
    cust_refunded.c_last_name AS refunded_last_name,
    cust_returning.c_customer_id AS returning_customer_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    promo_start.p_promo_name AS promo_start_name,
    promo_start.p_discount_active AS promo_start_discount_active,
    promo_end.p_promo_name AS promo_end_name,
    promo_end.p_discount_active AS promo_end_discount_active,
    d_ship.d_date AS first_ship_date,
    d_sales.d_date AS first_sales_date,
    date_diff('day', d_return.d_date, d_ship.d_date) AS days_to_first_ship,
    date_diff('day', d_return.d_date, d_sales.d_date) AS days_to_first_sales
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN customer cust_refunded
    ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer cust_returning
    ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN promotion promo_start
    ON promo_start.p_start_date_sk = d_return.d_date_sk
JOIN promotion promo_end
    ON promo_end.p_end_date_sk = d_return.d_date_sk
JOIN date_dim d_ship
    ON cust_refunded.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON cust_refunded.c_first_sales_date_sk = d_sales.d_date_sk
WHERE cr.cr_return_quantity > 0
ORDER BY total_return_value DESC
LIMIT 100
