SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_quantity) AS total_quantity_returned,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    AVG(d_ship.d_dow) AS avg_ship_day_of_week,
    CASE
        WHEN SUM(ws.ws_net_profit) = 0 THEN NULL
        ELSE SUM(sr.sr_net_loss) / SUM(ws.ws_net_profit)
    END AS loss_to_profit_ratio,
    MAX(d_closed.d_year) AS closure_year
FROM store s
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d
    ON d.d_date_sk = sr.sr_returned_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN date_dim d_ship
    ON d_ship.d_date_sk = ws.ws_ship_date_sk
LEFT JOIN date_dim d_closed
    ON d_closed.d_date_sk = s.s_closed_date_sk
WHERE d.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
