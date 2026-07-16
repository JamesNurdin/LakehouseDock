SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_state,
    sm.sm_type,
    sm.sm_carrier,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(cr.cr_return_tax) AS catalog_return_tax,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(wr.wr_return_tax) AS web_return_tax,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt) AS total_return_amount,
    CASE 
        WHEN (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) = 0 THEN 0
        ELSE (SUM(cr.cr_return_quantity) + SUM(wr.wr_return_quantity)) * 1.0 / (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt))
    END AS quantity_to_amount_ratio
FROM
    catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_state,
    sm.sm_type,
    sm.sm_carrier
ORDER BY
    total_return_amount DESC,
    d.d_date ASC
