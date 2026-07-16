SELECT
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    d_start.d_current_quarter AS page_start_quarter,
    d_end.d_current_quarter AS page_end_quarter,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_closing.d_current_year AS store_close_year,
    d_ret.d_day_name AS return_day_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
    SUM(ss.ss_ext_sales_price) AS total_gross_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT cr.cr_return_quantity) AS total_return_transactions,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    (SUM(ss.ss_net_paid) - SUM(cr.cr_return_amount)) AS net_sales_after_returns,
    ROUND(AVG(ss.ss_sales_price), 2) AS avg_sales_price,
    ROUND(AVG(cr.cr_return_amount), 2) AS avg_return_amount
FROM catalog_page cp
JOIN catalog_returns cr
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_end.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closing
    ON s.s_closed_date_sk = d_closing.d_date_sk
WHERE d_end.d_year = 2022
GROUP BY
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    d_start.d_current_quarter,
    d_end.d_current_quarter,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_closing.d_current_year,
    d_ret.d_day_name
ORDER BY net_sales_after_returns DESC
LIMIT 100
