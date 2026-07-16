SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    i.i_brand,
    i.i_category,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    d_ship.d_day_name AS ship_day_name,
    d_ship.d_month_seq AS ship_month,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    SUM(cr.cr_net_loss) AS total_return_loss,
    (SUM(cs.cs_net_paid) - SUM(cr.cr_net_loss)) AS net_gain,
    AVG(date_diff('day', d_sold.d_date, d_ret.d_date)) AS avg_days_to_return,
    MIN(cs.cs_quantity) AS min_quantity_sold,
    MAX(cs.cs_quantity) AS max_quantity_sold,
    AVG(cs.cs_net_profit) AS avg_net_profit_per_sale
FROM
    catalog_returns cr
JOIN
    catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
JOIN
    item i
        ON cr.cr_item_sk = i.i_item_sk
JOIN
    date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN
    date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN
    date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN
    store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE
    cr.cr_net_loss > 0
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    i.i_brand,
    i.i_category,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ship.d_day_name,
    d_ship.d_month_seq
ORDER BY
    net_gain DESC
LIMIT 100
