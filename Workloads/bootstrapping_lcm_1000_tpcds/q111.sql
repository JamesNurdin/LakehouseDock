SELECT
    s.s_store_name,
    s.s_city,
    d.d_date AS transaction_date,
    t_sales.t_hour AS sales_hour,
    t_returns.t_meal_time AS return_meal_time,
    d_closed.d_date AS store_closed_date,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_loss,
    AVG(ss.ss_quantity) AS avg_quantity_per_sale,
    AVG(cr.cr_return_quantity) AS avg_quantity_per_return
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t_returns
    ON cr.cr_returned_time_sk = t_returns.t_time_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    d.d_date,
    t_sales.t_hour,
    t_returns.t_meal_time,
    d_closed.d_date
ORDER BY total_sales DESC
LIMIT 100
