SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    s.s_state,
    s.s_city,
    cr.cr_item_sk,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_profit_after_returns,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(DATE_DIFF('day', d_sold.d_date, d_ret.d_date)) AS avg_days_to_return,
    AVG(DATE_DIFF('day', d_ship.d_date, d_ret.d_date)) AS avg_days_ship_to_return,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date
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
WHERE d_ret.d_year >= 2000
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_state,
    s.s_city,
    cr.cr_item_sk
ORDER BY total_sales_net_paid DESC
LIMIT 100
