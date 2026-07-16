SELECT
    s.s_store_name,
    sm.sm_type,
    d_date.d_year,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax,
    SUM(cr.cr_return_amount) AS total_catalog_return_amt,
    CASE
        WHEN (COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(cr.cr_net_loss), 0)) > 1000 THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM store s
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_date
    ON sr.sr_returned_date_sk = d_date.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_date.d_date_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_sc
    ON s.s_closed_date_sk = d_sc.d_date_sk
WHERE d_date.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_name,
    sm.sm_type,
    d_date.d_year
HAVING (SUM(sr.sr_return_quantity) + SUM(cr.cr_return_quantity)) > 0
ORDER BY total_store_net_loss DESC
LIMIT 100
