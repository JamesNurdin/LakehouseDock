SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_market_manager,
    cc.cc_city,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    ra.ca_city AS refunded_city,
    ra.ca_state AS refunded_state,
    ra.ca_country AS refunded_country,
    rca.ca_city AS returning_city,
    rca.ca_state AS returning_state,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    cr.cr_fee,
    cr.cr_return_tax,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY cr.cr_net_loss DESC) AS net_loss_rank
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN customer_address ra
    ON cr.cr_refunded_addr_sk = ra.ca_address_sk
JOIN customer_address rca
    ON cr.cr_returning_addr_sk = rca.ca_address_sk
WHERE d_ret.d_year = 2022
ORDER BY net_loss_rank, cc.cc_name
LIMIT 100
