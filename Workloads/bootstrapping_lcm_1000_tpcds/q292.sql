SELECT
    d.d_year AS return_year,
    d.d_month_seq AS month_seq,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_ext_tax) AS total_tax,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT s.s_store_sk) AS closed_stores,
    MIN(s.s_floor_space) AS min_store_floor_space,
    MAX(s.s_floor_space) AS max_store_floor_space,
    AVG(ws.ws_quantity) AS avg_quantity_per_sale,
    SUM(ws.ws_quantity * ws.ws_sales_price) AS total_sales_amount,
    CASE WHEN SUM(cr.cr_net_loss) = 0 THEN NULL ELSE SUM(ws.ws_net_profit) / SUM(cr.cr_net_loss) END AS profit_to_loss_ratio
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_ship_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY d.d_year, d.d_month_seq
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_return_loss DESC
LIMIT 100
