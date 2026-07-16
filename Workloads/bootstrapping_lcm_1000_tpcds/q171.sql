SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_loss,
    ROUND(100.0 * SUM(cr.cr_return_amount) / NULLIF(SUM(ss.ss_ext_sales_price), 0), 2) AS return_amount_pct,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    MIN(ds_sales.d_date) AS first_sale_date,
    MAX(ds_sales.d_date) AS last_sale_date,
    MIN(ds_closed.d_date) AS store_closed_date,
    MIN(dp_start.d_date) AS catalog_start_date,
    MIN(dp_end.d_date) AS catalog_end_date
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim ds_sales
    ON ss.ss_sold_date_sk = ds_sales.d_date_sk
JOIN date_dim ds_closed
    ON s.s_closed_date_sk = ds_closed.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = ds_closed.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dp_start
    ON cp.cp_start_date_sk = dp_start.d_date_sk
JOIN date_dim dp_end
    ON cp.cp_end_date_sk = dp_end.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY total_sales_amount DESC
LIMIT 100
