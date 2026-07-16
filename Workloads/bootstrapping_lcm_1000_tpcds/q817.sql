SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(cr.cr_return_quantity) AS total_returns,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_ext_sales_price) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_sales_after_returns,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(d_store_closed.d_date) AS store_closed_date,
    MIN(ws_open.web_rec_start_date) AS site_open_start_date,
    MAX(ws_close.web_rec_end_date) AS site_close_end_date,
    COUNT(DISTINCT ws_open.web_site_id) AS distinct_web_sites_opened,
    COUNT(DISTINCT ws_close.web_site_id) AS distinct_web_sites_closed
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
    AND cr.cr_item_sk = ss.ss_item_sk
LEFT JOIN web_site ws_open
    ON ws_open.web_open_date_sk = d_sales.d_date_sk
LEFT JOIN web_site ws_close
    ON ws_close.web_close_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2001
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY net_sales_after_returns DESC
LIMIT 20
