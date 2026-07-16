SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items_in_inventory,
    SUM(CASE WHEN cr.cr_return_amt_inc_tax > 100 THEN cr.cr_return_amt_inc_tax ELSE 0 END) AS high_value_return_amt,
    COUNT(*) FILTER (WHERE cr.cr_return_tax > 0) AS returns_with_tax,
    MAX(d.d_date) AS latest_return_date
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2018
  AND s.s_state IS NOT NULL
GROUP BY d.d_year, d.d_month_seq, s.s_state
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
