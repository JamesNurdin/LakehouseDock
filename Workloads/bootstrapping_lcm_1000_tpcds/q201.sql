SELECT
    d.d_year,
    d.d_moy,
    (d.d_year * 100 + d.d_moy) AS year_month,
    i.i_category,
    s.s_state,
    CASE
        WHEN cr.cr_net_loss > 1000 THEN 'High'
        WHEN cr.cr_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    COUNT(*) AS return_count,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount * s.s_tax_percentage / 100) AS tax_adjusted_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    d.d_moy,
    (d.d_year * 100 + d.d_moy),
    i.i_category,
    s.s_state,
    CASE
        WHEN cr.cr_net_loss > 1000 THEN 'High'
        WHEN cr.cr_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
