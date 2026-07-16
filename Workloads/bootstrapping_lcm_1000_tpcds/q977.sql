SELECT
    cp.cp_department,
    cp.cp_type,
    s.s_store_name,
    s.s_state,
    dp.d_year,
    dp.d_month_seq,
    (dp.d_year * 100 + dp.d_month_seq) AS year_month,
    ca_refunded.ca_state AS refunded_state,
    ca_returning.ca_city AS returning_city,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr.cr_return_amount) > 20000 THEN 'HIGH'
        WHEN SUM(cr.cr_return_amount) > 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_amount_category
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dp
    ON cr.cr_returned_date_sk = dp.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE dp.d_date BETWEEN d_start.d_date AND d_end.d_date
  AND s.s_state = 'CA'
  AND cp.cp_type = 'Holiday'
GROUP BY
    cp.cp_department,
    cp.cp_type,
    s.s_store_name,
    s.s_state,
    dp.d_year,
    dp.d_month_seq,
    ca_refunded.ca_state,
    ca_returning.ca_city
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 50
