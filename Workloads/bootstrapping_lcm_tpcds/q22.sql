SELECT
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    i.i_category,
    s.s_state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(*) AS return_rows,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    i.i_category,
    s.s_state
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
