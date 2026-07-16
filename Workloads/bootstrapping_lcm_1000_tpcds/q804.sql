SELECT
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_refunded_cash) AS avg_refunded_cash,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ref.cd_gender,
    cd_ret.cd_gender
ORDER BY total_net_loss DESC
LIMIT 10
