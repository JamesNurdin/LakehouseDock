SELECT 
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_description,
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_cp_end.d_date AS catalog_page_end_date,
    d_closed.d_date AS store_closed_date,
    t.t_hour,
    t.t_minute,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
CROSS JOIN store s
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE 
    t.t_hour BETWEEN 9 AND 18
    AND s.s_state = 'CA'
GROUP BY 
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_description,
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_cp_end.d_date,
    d_closed.d_date,
    t.t_hour,
    t.t_minute,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY total_net_loss DESC
LIMIT 100
