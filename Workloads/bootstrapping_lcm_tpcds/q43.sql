SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d.d_year AS return_year,
    d.d_month_seq AS return_month_seq,
    d.d_day_name AS return_day_name,
    rc.c_customer_id AS returning_customer_id,
    rc.c_first_name AS returning_first_name,
    rc.c_last_name AS returning_last_name,
    rc.c_birth_country AS returning_birth_country,
    raddr.ca_city AS returning_address_city,
    raddr.ca_state AS returning_address_state,
    caddr.ca_city AS returning_current_city,
    caddr.ca_state AS returning_current_state,
    fc.c_customer_id AS refunded_customer_id,
    fc.c_preferred_cust_flag AS refunded_preferred_flag,
    faddr.ca_city AS refunded_address_city,
    faddr.ca_state AS refunded_address_state,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_return_tax,
    cr.cr_net_loss,
    cr.cr_return_amt_inc_tax,
    cr.cr_fee,
    cr.cr_store_credit,
    cr.cr_return_ship_cost,
    date_diff('day', rc_first_ship.d_date, d.d_date) AS days_since_customer_first_ship,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_return_amount DESC) AS rn_return_amount
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN customer rc ON cr.cr_returning_customer_sk = rc.c_customer_sk
JOIN customer_address raddr ON cr.cr_returning_addr_sk = raddr.ca_address_sk
JOIN customer_address caddr ON rc.c_current_addr_sk = caddr.ca_address_sk
JOIN customer fc ON cr.cr_refunded_customer_sk = fc.c_customer_sk
JOIN customer_address faddr ON cr.cr_refunded_addr_sk = faddr.ca_address_sk
JOIN date_dim rc_first_ship ON rc.c_first_shipto_date_sk = rc_first_ship.d_date_sk
WHERE rc.c_preferred_cust_flag = 'Y'
ORDER BY cr.cr_return_amount DESC
LIMIT 100
