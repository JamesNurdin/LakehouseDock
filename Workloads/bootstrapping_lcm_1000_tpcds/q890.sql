SELECT
    d.d_year,
    d.d_month_seq,
    w.w_state,
    w.w_warehouse_name,
    s.s_state,
    s.s_city,
    CASE
        WHEN d.d_quarter_seq <= 2 THEN 'Q1_Q2'
        ELSE 'Q3_Q4'
    END AS half_quarter_group,
    COUNT(*) AS total_returns,
    COUNT(*) FILTER (WHERE cr.cr_return_quantity > 5) AS high_qty_catalog_returns,
    COUNT(*) FILTER (WHERE wr.wr_return_quantity > 5) AS high_qty_web_returns,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) / NULLIF(SUM(wr.wr_return_amt), 0) AS catalog_to_web_return_ratio,
    AVG(cr.cr_return_quantity) AS avg_catalog_qty,
    AVG(wr.wr_return_quantity) AS avg_web_qty
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_month_seq,
    w.w_state,
    w.w_warehouse_name,
    s.s_state,
    s.s_city,
    CASE
        WHEN d.d_quarter_seq <= 2 THEN 'Q1_Q2'
        ELSE 'Q3_Q4'
    END
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
