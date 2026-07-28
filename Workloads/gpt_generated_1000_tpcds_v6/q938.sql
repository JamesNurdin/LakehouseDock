SELECT
    d_sold.d_year,
    i.i_category,
    i.i_brand,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    AVG(cs.cs_quantity) AS avg_quantity_sold,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN reason r_return ON cr.cr_reason_sk = r_return.r_reason_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
LEFT JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE cs.cs_net_paid_inc_tax > (
    SELECT AVG(cs2.cs_net_paid_inc_tax)
    FROM catalog_sales cs2
)
GROUP BY d_sold.d_year, i.i_category, i.i_brand
ORDER BY total_net_paid DESC
LIMIT 100
