SELECT
    d_ret.d_year,
    d_ret.d_quarter_seq,
    s.s_state,
    d_ship.d_month_seq AS ship_month,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_sales,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales_net_paid,
    SUM(ws.ws_net_profit) AS total_web_profit,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    SUM(i.inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
WHERE cr.cr_net_loss > 0
  AND ws.ws_net_profit > 0
  AND i.inv_quantity_on_hand > 0
GROUP BY d_ret.d_year, d_ret.d_quarter_seq, s.s_state, d_ship.d_month_seq
ORDER BY d_ret.d_year, d_ret.d_quarter_seq, s.s_state, d_ship.d_month_seq
LIMIT 100
