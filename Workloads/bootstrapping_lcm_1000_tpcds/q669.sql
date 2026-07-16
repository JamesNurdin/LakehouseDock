SELECT
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_quarter_name,
    i.i_category,
    i.i_product_name,
    i.i_item_sk,
    ca_refund.ca_state AS refunded_state,
    ca_refund.ca_city AS refunded_city,
    ca_return.ca_state AS returning_state,
    ca_return.ca_city AS returning_city,
    s.s_store_name,
    s.s_state AS store_state,
    s.s_city AS store_city,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    AVG(cr.cr_return_amount) AS avg_return_amount
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
    ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_quarter_name,
    i.i_category,
    i.i_product_name,
    i.i_item_sk,
    ca_refund.ca_state,
    ca_refund.ca_city,
    ca_return.ca_state,
    ca_return.ca_city,
    s.s_store_name,
    s.s_state,
    s.s_city
ORDER BY total_net_loss DESC
LIMIT 100
