SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_ret.d_year,
    d_ret.d_moy AS month,
    d_ret.d_date,
    ca_ret.ca_city AS returning_city,
    ca_ret.ca_state AS returning_state,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    hd_ret.hd_vehicle_count AS returning_vehicle_count,
    ca_ref.ca_city AS refunded_city,
    ca_ref.ca_state AS refunded_state,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    hd_ref.hd_vehicle_count AS refunded_vehicle_count,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_return_tax) AS total_return_tax,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT hd_ref.hd_demo_sk) AS distinct_refunded_households,
    COUNT(DISTINCT ca_ref.ca_city) AS distinct_refunded_cities
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
WHERE d_ret.d_year = 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_moy,
    d_ret.d_date,
    ca_ret.ca_city,
    ca_ret.ca_state,
    hd_ret.hd_buy_potential,
    hd_ret.hd_vehicle_count,
    ca_ref.ca_city,
    ca_ref.ca_state,
    hd_ref.hd_buy_potential,
    hd_ref.hd_vehicle_count
ORDER BY total_net_loss DESC
LIMIT 100
