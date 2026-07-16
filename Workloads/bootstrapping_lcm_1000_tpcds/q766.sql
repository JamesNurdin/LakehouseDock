SELECT
    s.s_store_id,
    s.s_city AS store_city,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    d.d_year,
    d.d_month_seq,
    (d.d_year * 100 + d.d_month_seq) AS year_month,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(CASE WHEN d.d_holiday = 'Y' THEN cr.cr_return_amount ELSE 0 END) AS holiday_return_amount,
    SUM(CASE WHEN d.d_day_name IN ('Saturday', 'Sunday') THEN cr.cr_return_amount ELSE 0 END) AS weekend_return_amount
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
    AND i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND w.w_state = 'CA'
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    w.w_warehouse_name,
    w.w_city,
    d.d_year,
    d.d_month_seq,
    (d.d_year * 100 + d.d_month_seq)
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
