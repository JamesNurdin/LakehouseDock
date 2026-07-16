SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_return_ship_cost,
    cr.cr_fee,
    (cr.cr_return_amount + cr.cr_return_tax + cr.cr_return_ship_cost + cr.cr_fee) AS total_refund_amount,
    cr.cr_net_loss,
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    cr_cust.c_customer_id AS returning_customer_id,
    cr_cust.c_first_name AS returning_first_name,
    cr_cust.c_last_name AS returning_last_name,
    rf_cust.c_customer_id AS refunded_customer_id,
    rf_cust.c_first_name AS refunded_first_name,
    rf_cust.c_last_name AS refunded_last_name,
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    w.web_site_id,
    w.web_name,
    w.web_city AS website_city,
    w.web_country,
    d_ship.d_date AS first_ship_date,
    d_sales.d_date AS first_sales_date,
    d_rev.d_date AS last_review_date,
    d_web_close.d_date AS website_close_date,
    ROW_NUMBER() OVER (ORDER BY cr.cr_net_loss DESC) AS loss_rank
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer cr_cust
    ON cr.cr_returning_customer_sk = cr_cust.c_customer_sk
JOIN customer rf_cust
    ON cr.cr_refunded_customer_sk = rf_cust.c_customer_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
LEFT JOIN web_site w
    ON w.web_open_date_sk = d_ret.d_date_sk
LEFT JOIN date_dim d_ship
    ON cr_cust.c_first_shipto_date_sk = d_ship.d_date_sk
LEFT JOIN date_dim d_sales
    ON cr_cust.c_first_sales_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_rev
    ON cr_cust.c_last_review_date = d_rev.d_date_sk
LEFT JOIN date_dim d_web_close
    ON w.web_close_date_sk = d_web_close.d_date_sk
ORDER BY cr.cr_net_loss DESC, d_ret.d_date
