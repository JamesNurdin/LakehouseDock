SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_fee,
    (cr.cr_return_amount - cr.cr_fee - cr.cr_net_loss) AS net_return,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_ret.d_date AS return_date,
    c_ref.c_customer_id,
    c_ref.c_first_name,
    c_ref.c_last_name,
    ca_ref.ca_city AS refunded_city,
    ca_ref.ca_state AS refunded_state,
    ca_curr.ca_city AS current_city,
    ca_curr.ca_state AS current_state,
    d_sales.d_year AS first_sales_year,
    d_sales.d_month_seq AS first_sales_month_seq,
    d_ship.d_year AS first_ship_year,
    d_ship.d_month_seq AS first_ship_month_seq,
    d_review.d_year AS last_review_year,
    date_diff('day', d_ret.d_date, d_sales.d_date) AS days_since_first_sale,
    s.s_store_id,
    s.s_city AS store_city,
    s.s_state,
    d_store.d_year AS store_close_year,
    d_store.d_month_seq AS store_close_month_seq,
    c_ret.c_customer_id AS returning_customer_id,
    c_ret.c_first_name AS returning_first_name,
    ca_ret.ca_city AS returning_city,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_net_loss DESC) AS loss_rank_by_store
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN customer_address ca_curr
    ON c_ref.c_current_addr_sk = ca_curr.ca_address_sk
JOIN date_dim d_sales
    ON c_ref.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON c_ref.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_review
    ON c_ref.c_last_review_date = d_review.d_date_sk
WHERE cr.cr_return_amount > 0
ORDER BY cr.cr_net_loss DESC
LIMIT 100
