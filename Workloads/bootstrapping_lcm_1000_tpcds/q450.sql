SELECT
    cp.cp_catalog_number,
    cp.cp_type,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_start.d_date AS catalog_start_date,
    d_end.d_date AS catalog_end_date,
    d_return.d_date AS return_date,
    d_store_closed.d_date AS store_closed_date,
    COUNT(DISTINCT cr.cr_return_quantity) AS num_return_transactions,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity_sold
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_return.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    cp.cp_catalog_number,
    cp.cp_type,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_start.d_date,
    d_end.d_date,
    d_return.d_date,
    d_store_closed.d_date
ORDER BY total_net_profit DESC
LIMIT 100
