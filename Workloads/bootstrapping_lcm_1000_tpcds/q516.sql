SELECT
    s.s_store_id,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq AS month,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_gain,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(d_ship.d_week_seq) AS first_ship_week
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq
ORDER BY net_gain DESC
LIMIT 100
