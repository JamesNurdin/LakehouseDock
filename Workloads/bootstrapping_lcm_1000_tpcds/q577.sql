SELECT
    d_cr.d_year,
    d_cr.d_month_seq,
    s.s_division_id,
    ws.web_mkt_id,
    CASE
        WHEN s.s_state IN ('CA', 'WA', 'OR') THEN 'West Coast'
        WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East Coast'
        ELSE 'Other'
    END AS region_group,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    SUM(cr.cr_fee + wr.wr_fee) AS total_fees,
    SUM(cr.cr_return_tax + wr.wr_return_tax) AS total_return_tax
FROM catalog_returns cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_cr.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_cr.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_cr.d_year BETWEEN 2000 AND 2002
GROUP BY
    d_cr.d_year,
    d_cr.d_month_seq,
    s.s_division_id,
    ws.web_mkt_id,
    CASE
        WHEN s.s_state IN ('CA', 'WA', 'OR') THEN 'West Coast'
        WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East Coast'
        ELSE 'Other'
    END
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_catalog_return_amount DESC
LIMIT 100
