SELECT
    cs.cs_item_sk,
    d_sold.d_year,
    CASE WHEN d_sold.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT s.s_store_sk) AS stores_closed,
    (SUM(cs.cs_net_paid_inc_tax) - SUM(cr.cr_net_loss)) AS net_contribution
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY cs.cs_item_sk,
         d_sold.d_year,
         CASE WHEN d_sold.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END
HAVING SUM(cs.cs_net_paid_inc_tax) > 0
ORDER BY net_contribution DESC
LIMIT 100
