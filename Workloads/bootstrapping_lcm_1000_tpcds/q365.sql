SELECT
    s.s_store_id,
    s.s_city,
    cp.cp_department,
    cp.cp_catalog_page_number,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss) AS net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    d_closed.d_year AS store_closed_year,
    d_cp_start.d_year AS catalog_start_year,
    d_cp_end.d_year AS catalog_end_year
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sales.d_year = 2022
  AND d_closed.d_year >= 2020
  AND d_cp_start.d_year <= 2022
  AND d_cp_end.d_year >= 2022
GROUP BY
    s.s_store_id,
    s.s_city,
    cp.cp_department,
    cp.cp_catalog_page_number,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_closed.d_year,
    d_cp_start.d_year,
    d_cp_end.d_year
ORDER BY total_sales_amount DESC
LIMIT 100
