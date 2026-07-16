SELECT
    d.d_year,
    (d.d_month_seq + 2) / 3 AS quarter,
    s.s_division_id,
    COUNT(DISTINCT cr.cr_order_number) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cust.c_customer_sk) AS distinct_customers,
    CASE
        WHEN SUM(cr.cr_return_amount) > 50000 THEN 'HIGH'
        WHEN SUM(cr.cr_return_amount) > 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_amount_category
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY d.d_year, (d.d_month_seq + 2) / 3, s.s_division_id
ORDER BY d.d_year, quarter, s.s_division_id
LIMIT 100
