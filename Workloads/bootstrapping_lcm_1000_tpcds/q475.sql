SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cp.cp_description,
    cp.cp_type,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_fee,
    ca_refunded.ca_city AS refunded_city,
    ca_refunded.ca_state AS refunded_state,
    ca_refunded.ca_zip AS refunded_zip,
    ca_returning.ca_city AS returning_city,
    ca_returning.ca_state AS returning_state,
    ca_returning.ca_zip AS returning_zip,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_ret.d_day_name AS return_day_name,
    d_end.d_year AS page_end_year,
    d_end.d_month_seq AS page_end_month_seq,
    d_start.d_year AS page_start_year,
    d_start.d_month_seq AS page_start_month_seq,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_market_desc,
    d_store.d_year AS store_closed_year,
    d_store.d_month_seq AS store_closed_month_seq
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
ORDER BY cr.cr_net_loss DESC
LIMIT 100
