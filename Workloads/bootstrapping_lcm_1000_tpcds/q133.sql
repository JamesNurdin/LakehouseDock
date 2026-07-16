SELECT
    s.s_state,
    d_return.d_year,
    d_return.d_moy,
    t_return.t_hour,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    COUNT(*) AS num_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(date_diff('day', d_sold.d_date, d_return.d_date)) AS avg_days_between_sale_and_return,
    AVG(date_diff('day', d_ship.d_date, d_return.d_date)) AS avg_days_between_ship_and_return,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_ext_tax) AS total_tax_amount
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE cs.cs_net_paid IS NOT NULL
GROUP BY
    s.s_state,
    d_return.d_year,
    d_return.d_moy,
    t_return.t_hour,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
HAVING COUNT(*) > 10
ORDER BY total_sales_net_paid DESC
LIMIT 100
