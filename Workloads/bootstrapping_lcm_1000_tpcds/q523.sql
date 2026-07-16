SELECT
    d.d_year,
    d.d_month_seq,
    w.w_state AS warehouse_state,
    ca_refunded.ca_city AS refunded_city,
    ca_returning.ca_city AS returning_city,
    s.s_state AS store_state,
    COUNT(*) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN ca_refunded.ca_city = ca_returning.ca_city THEN cr.cr_fee ELSE 0 END) AS intra_city_fee,
    SUM(cr.cr_fee * cr.cr_return_quantity) AS total_fee,
    SUM(cr.cr_net_loss) / NULLIF(COUNT(*), 0) AS net_loss_per_return,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND s.s_number_employees > 0
GROUP BY
    d.d_year,
    d.d_month_seq,
    w.w_state,
    ca_refunded.ca_city,
    ca_returning.ca_city,
    s.s_state
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
