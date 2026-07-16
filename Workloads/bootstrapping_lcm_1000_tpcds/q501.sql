SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_return.d_date AS store_closed_date,
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    w.w_state AS warehouse_state,
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_end.d_date AS catalog_end_date,
    DATE_TRUNC('month', d_return.d_date) AS return_month,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_return.d_year = 2022
  AND w.w_state = 'CA'
  AND s.s_state = 'CA'
  AND cp.cp_type = 'PROMO'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_return.d_date,
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_cp_start.d_date,
    d_cp_end.d_date,
    DATE_TRUNC('month', d_return.d_date)
ORDER BY total_net_loss DESC
LIMIT 100
