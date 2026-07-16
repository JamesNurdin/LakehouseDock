SELECT
    (d.d_year * 100 + d.d_month_seq) AS year_month_key,
    s.s_state,
    wp.wp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_net_loss,
    MAX(cr.cr_fee) AS max_fee,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1995 AND 2005
  AND s.s_state IS NOT NULL
GROUP BY
    (d.d_year * 100 + d.d_month_seq),
    s.s_state,
    wp.wp_type
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY total_return_amount DESC
LIMIT 100
