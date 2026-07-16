SELECT
    s.s_store_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    t_sold.t_hour,
    CASE 
        WHEN t_sold.t_hour BETWEEN 0 AND 6 THEN 'Late Night'
        WHEN t_sold.t_hour BETWEEN 7 AND 12 THEN 'Morning'
        WHEN t_sold.t_hour BETWEEN 13 AND 18 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_paid) - SUM(cr.cr_net_loss) AS net_revenue,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_returns,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
    AVG(date_diff('day', d_sold.d_date, d_ret.d_date)) AS avg_return_lag_days
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cs.cs_item_sk = cr.cr_item_sk
    AND cs.cs_order_number = cr.cr_order_number
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
GROUP BY
    s.s_store_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    t_sold.t_hour,
    CASE 
        WHEN t_sold.t_hour BETWEEN 0 AND 6 THEN 'Late Night'
        WHEN t_sold.t_hour BETWEEN 7 AND 12 THEN 'Morning'
        WHEN t_sold.t_hour BETWEEN 13 AND 18 THEN 'Afternoon'
        ELSE 'Evening'
    END
HAVING SUM(cs.cs_net_paid) - SUM(cr.cr_net_loss) > 0
ORDER BY net_revenue DESC
LIMIT 100
