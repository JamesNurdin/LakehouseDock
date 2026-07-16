SELECT
    s.s_store_id,
    s.s_store_name,
    d_closed.d_year AS store_closed_year,
    d_sold.d_year AS sales_year,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(cr.cr_order_number) AS total_returns,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_days,
    AVG(date_diff('day', d_sold.d_date, d_returned.d_date)) AS avg_return_days,
    (SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_after_returns,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(cs.cs_coupon_amt) AS total_coupon_amount
FROM store s
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
CROSS JOIN catalog_sales cs
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_returned
    ON cr.cr_returned_date_sk = d_returned.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_closed.d_year,
    d_sold.d_year
ORDER BY net_profit_after_returns DESC
LIMIT 100
