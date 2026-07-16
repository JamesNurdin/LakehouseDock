SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sales.d_date,
    t_sales.t_hour AS sale_hour,
    MAX(t_return.t_hour) AS return_hour,
    MAX(t_return.t_hour) - t_sales.t_hour AS return_hour_lag,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_quantity) AS total_units_sold,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_after_returns,
    CASE WHEN s.s_closed_date_sk IS NOT NULL AND s.s_closed_date_sk = d_sales.d_date_sk THEN 1 ELSE 0 END AS is_closed_on_sale_date,
    d_closure.d_date AS store_closed_date,
    DATE_DIFF('day', d_sales.d_date, d_closure.d_date) AS days_to_closure,
    RANK() OVER (ORDER BY (SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) DESC) AS profit_rank
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr
    ON ss.ss_sold_date_sk = cr.cr_returned_date_sk
   AND ss.ss_sold_time_sk = cr.cr_returned_time_sk
   AND ss.ss_item_sk = cr.cr_item_sk
LEFT JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
LEFT JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sales.d_date,
    t_sales.t_hour,
    s.s_closed_date_sk,
    d_closure.d_date,
    d_sales.d_date_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
