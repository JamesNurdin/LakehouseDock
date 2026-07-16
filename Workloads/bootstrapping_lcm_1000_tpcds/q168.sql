SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_positive_loss,
    SUM(CASE WHEN cr.cr_net_loss < 0 THEN cr.cr_net_loss ELSE 0 END) AS total_negative_loss,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    ROUND(AVG(i.i_current_price), 2) AS avg_item_price,
    MAX(i.i_wholesale_cost) AS max_wholesale_cost,
    MIN(i.i_wholesale_cost) AS min_wholesale_cost,
    SUM(cr.cr_fee) AS total_fees,
    SUM(cr.cr_fee) / NULLIF(COUNT(*), 0) AS avg_fee_per_return,
    SUM(cr.cr_return_tax) AS total_tax,
    CASE
        WHEN SUM(cr.cr_return_amount) = 0 THEN 0
        ELSE SUM(cr.cr_return_tax) / SUM(cr.cr_return_amount)
    END AS tax_to_return_ratio,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    s.s_state,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
