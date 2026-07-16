SELECT
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_state,
    w.w_state,
    COUNT(*) AS total_returns,
    SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    SUM(COALESCE(cr.cr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0)) AS total_quantity,
    AVG(COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS avg_return_amount,
    SUM(
        CASE
            WHEN (COALESCE(cr.cr_return_amt_inc_tax, 0) + COALESCE(wr.wr_return_amt_inc_tax, 0)) > 100
            THEN 1
            ELSE 0
        END
    ) AS high_value_returns,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    s.s_state,
    w.w_state
HAVING SUM(COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 0
ORDER BY total_net_loss DESC
LIMIT 100
