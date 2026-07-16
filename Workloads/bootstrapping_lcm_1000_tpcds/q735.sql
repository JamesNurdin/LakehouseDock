SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    cp.cp_catalog_page_id,
    cp.cp_description,
    d_return.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss)) AS net_profit_adj,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    DATE_DIFF('day', d_start.d_date, d_end.d_date) AS catalog_page_duration_days,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 0
        THEN SUM(cr.cr_return_amount) / SUM(ss.ss_ext_sales_price)
        ELSE NULL
    END AS return_rate
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_return.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_return.d_year = 2021
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    cp.cp_catalog_page_id,
    cp.cp_description,
    d_return.d_year,
    d_start.d_date,
    d_end.d_date
ORDER BY net_profit_adj DESC
LIMIT 100
