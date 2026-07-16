SELECT
    d.d_year,
    d.d_month_seq,
    CASE
        WHEN t.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    s.s_store_id,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(cr.cr_return_quantity + wr.wr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_ship_cost) AS avg_catalog_ship_cost,
    AVG(wr.wr_return_ship_cost) AS avg_web_ship_cost
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4
