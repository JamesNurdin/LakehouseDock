SELECT
    d.d_year,
    d.d_quarter_name,
    w.w_state AS warehouse_state,
    s.s_state AS store_state,
    CASE
        WHEN w.w_warehouse_sq_ft > 500000 THEN 'HUGE'
        WHEN w.w_warehouse_sq_ft > 200000 THEN 'LARGE'
        ELSE 'SMALL'
    END AS warehouse_size_category,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(cr.cr_return_quantity + sr.sr_return_quantity) AS total_return_qty,
    AVG(cr.cr_return_amt_inc_tax) AS avg_catalog_return_amt_inc_tax,
    AVG(sr.sr_return_amt_inc_tax) AS avg_store_return_amt_inc_tax,
    CASE
        WHEN SUM(sr.sr_net_loss) <> 0 THEN SUM(cr.cr_net_loss) / SUM(sr.sr_net_loss)
        ELSE NULL
    END AS loss_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_store_sk = s.s_store_sk
GROUP BY
    d.d_year,
    d.d_quarter_name,
    w.w_state,
    s.s_state,
    CASE
        WHEN w.w_warehouse_sq_ft > 500000 THEN 'HUGE'
        WHEN w.w_warehouse_sq_ft > 200000 THEN 'LARGE'
        ELSE 'SMALL'
    END
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_catalog_net_loss DESC
LIMIT 100
