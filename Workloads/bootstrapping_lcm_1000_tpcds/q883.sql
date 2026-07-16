SELECT
    cp.cp_department AS department,
    s.s_state AS store_state,
    dr.d_year AS return_year,
    dr.d_current_month AS return_month,
    dcp_start.d_year AS page_start_year,
    dcp_end.d_year AS page_end_year,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    CASE
        WHEN SUM(wr.wr_return_amt) = 0 THEN NULL
        ELSE SUM(cr.cr_return_amount) / SUM(wr.wr_return_amt)
    END AS catalog_to_web_return_amount_ratio
FROM
    catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN date_dim dcp_start ON cp.cp_start_date_sk = dcp_start.d_date_sk
    JOIN date_dim dcp_end ON cp.cp_end_date_sk = dcp_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = dr.d_date_sk
WHERE
    dr.d_year >= 2000
GROUP BY
    cp.cp_department,
    s.s_state,
    dr.d_year,
    dr.d_current_month,
    dcp_start.d_year,
    dcp_end.d_year
HAVING
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
