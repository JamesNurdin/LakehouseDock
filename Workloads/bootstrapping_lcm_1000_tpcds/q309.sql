SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    s.s_city,
    CASE
        WHEN (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) > 5000 THEN 'High'
        ELSE 'Low'
    END AS return_amount_category,
    COUNT(*) AS transaction_count,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    (SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity)) AS total_return_qty,
    CASE
        WHEN (SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity)) > 0
        THEN (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) /
             (SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity))
        ELSE 0
    END AS avg_return_amount_per_item,
    (SUM(cr.cr_fee) + SUM(wr.wr_fee)) AS total_fees,
    (SUM(cr.cr_return_tax) + SUM(wr.wr_return_tax)) AS total_tax,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    CASE
        WHEN (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) > 0
        THEN (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) /
             (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt))
        ELSE 0
    END AS net_loss_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2025
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    s.s_city
