SELECT
    s.s_store_id,
    d_sold.d_year,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_profit_after_returns,
    CASE
        WHEN SUM(cs.cs_net_paid) = 0 THEN NULL
        ELSE (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) / SUM(cs.cs_net_paid)
    END AS profit_margin,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(CASE WHEN cs.cs_coupon_amt > 0 THEN cs.cs_coupon_amt ELSE 0 END) AS total_coupons_used,
    SUM(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_fees,
    SUM(CASE WHEN d_ship.d_dow = 6 THEN cs.cs_quantity ELSE 0 END) AS saturday_quantity_sold
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
    ON inv.inv_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2001
  AND s.s_state = 'CA'
GROUP BY s.s_store_id, d_sold.d_year
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
