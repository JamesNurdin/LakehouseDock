SELECT
    dr.d_year AS return_year,
    dr.d_month_seq AS return_month,
    ds.d_year AS sold_year,
    dsh.d_year AS ship_year,
    s.s_store_name,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_profit_after_returns
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim ds
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh
    ON cs.cs_ship_date_sk = dsh.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = dr.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
WHERE dr.d_year = 2022
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    ds.d_year,
    dsh.d_year,
    s.s_store_name,
    s.s_state
ORDER BY total_sales_net_paid DESC
LIMIT 100
