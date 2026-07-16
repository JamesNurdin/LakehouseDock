SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    t.t_hour,
    t.t_meal_time,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cs.cs_quantity) AS total_sold_quantity,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    ROUND(SUM(cr.cr_net_loss) / NULLIF(SUM(cs.cs_net_profit), 0), 2) AS loss_to_profit_ratio
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_ship_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
    AND cs.cs_sold_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    t.t_hour,
    t.t_meal_time
ORDER BY total_net_loss DESC
LIMIT 100
