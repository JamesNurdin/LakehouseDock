SELECT
    cr.cr_order_number,
    d.d_date,
    d.d_year,
    t.t_hour,
    t.t_meal_time,
    s.s_store_name,
    s.s_state,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(ss.ss_ticket_number) AS sales_transactions,
    COUNT(cr.cr_return_quantity) AS return_transactions
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_sold_time_sk = t.t_time_sk
    AND ss.ss_store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 2020 AND 2023
GROUP BY
    cr.cr_order_number,
    d.d_date,
    d.d_year,
    t.t_hour,
    t.t_meal_time,
    s.s_store_name,
    s.s_state
ORDER BY total_sales DESC
LIMIT 100
