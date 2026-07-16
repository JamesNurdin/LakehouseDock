SELECT
    ret_date.d_year AS return_year,
    ret_date.d_month_seq AS return_month,
    s.s_division_id,
    ws.web_state,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT c_ref.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT c_ret.c_customer_sk) AS distinct_returning_customers,
    MIN(first_sales_date.d_year) AS first_sales_year,
    MAX(last_review_date.d_year) AS last_review_year,
    MAX(ws_close_date.d_year) AS web_site_close_latest_year
FROM catalog_returns cr
JOIN date_dim ret_date
    ON cr.cr_returned_date_sk = ret_date.d_date_sk
JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
    ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = ret_date.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = ret_date.d_date_sk
LEFT JOIN date_dim first_sales_date
    ON c_ref.c_first_sales_date_sk = first_sales_date.d_date_sk
LEFT JOIN date_dim first_ship_date
    ON c_ref.c_first_shipto_date_sk = first_ship_date.d_date_sk
LEFT JOIN date_dim last_review_date
    ON c_ref.c_last_review_date = last_review_date.d_date_sk
LEFT JOIN date_dim ws_close_date
    ON ws.web_close_date_sk = ws_close_date.d_date_sk
GROUP BY
    ret_date.d_year,
    ret_date.d_month_seq,
    s.s_division_id,
    ws.web_state
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
