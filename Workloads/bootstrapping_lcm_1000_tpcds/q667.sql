SELECT
    (d.d_year * 100 + d.d_month_seq) AS year_month,
    ca_refund.ca_state AS refunded_state,
    ca_return.ca_state AS returning_state,
    w.w_city AS warehouse_city,
    s.s_market_desc,
    COUNT(*) AS return_count,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_tax) AS total_tax,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    SUM(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_fee
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
    ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND w.w_state = 'CA'
GROUP BY
    (d.d_year * 100 + d.d_month_seq),
    ca_refund.ca_state,
    ca_return.ca_state,
    w.w_city,
    s.s_market_desc
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
