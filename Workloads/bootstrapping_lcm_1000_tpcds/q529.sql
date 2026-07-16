SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    sm.sm_type AS ship_mode,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_return_quantity,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_sales_after_returns,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 0
        THEN COALESCE(SUM(cr.cr_return_amount), 0) / SUM(ss.ss_ext_sales_price)
        ELSE 0
    END AS return_rate,
    d_closed.d_year AS store_closed_year
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    sm.sm_type,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_closed.d_year
ORDER BY total_profit DESC
LIMIT 100
