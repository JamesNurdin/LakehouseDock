SELECT
    d.d_year,
    d.d_month_seq,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    CASE 
        WHEN s.s_state IN ('CA','NY','TX') THEN 'Major'
        ELSE 'Other'
    END AS state_group,
    sm.sm_type,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS avg_return_amount_per_row,
    SUM(cr.cr_fee) + SUM(wr.wr_fee) AS total_fees,
    SUM(cr.cr_return_amount) - SUM(cr.cr_fee) AS net_catalog_return_minus_fees,
    SUM(wr.wr_return_amt) - SUM(wr.wr_fee) AS net_web_return_minus_fees
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_month_seq,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END,
    CASE 
        WHEN s.s_state IN ('CA','NY','TX') THEN 'Major'
        ELSE 'Other'
    END,
    sm.sm_type
HAVING (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) > 10000
ORDER BY d.d_year, d.d_month_seq, sm.sm_type
LIMIT 100
