SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month_seq,
    ws.web_name,
    ws.web_manager,
    d_sales.d_year AS web_open_year,
    d_ws_close.d_year AS web_close_year,
    d_store_closed.d_year AS store_closed_year,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0)) AS net_sales_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    CASE WHEN COALESCE(SUM(cr.cr_return_amount), 0) = 0 THEN NULL
         ELSE (SUM(ss.ss_ext_sales_price) / COALESCE(SUM(cr.cr_return_amount), 0))
    END AS sales_to_return_ratio,
    ROW_NUMBER() OVER (
        ORDER BY (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0)) DESC
    ) AS sales_rank
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sales.d_year,
    d_sales.d_month_seq,
    ws.web_name,
    ws.web_manager,
    d_ws_close.d_year,
    d_store_closed.d_year
ORDER BY net_sales_amount DESC
LIMIT 100
