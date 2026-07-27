WITH ws_filtered AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_wholesale_cost,
        ws.ws_order_number,
        ws.ws_ship_date_sk
    FROM web_sales ws
    WHERE ws.ws_wholesale_cost > 30
      AND ws.ws_quantity BETWEEN 1 AND 5
      AND ws.ws_net_profit > 0
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_channel_dmail,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    MIN(inv.inv_quantity_on_hand) AS min_inventory,
    MAX(inv.inv_quantity_on_hand) AS max_inventory
FROM ws_filtered ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_sold.d_date_sk
WHERE p.p_channel_dmail = 'Y'
  AND p.p_cost < 500
  AND d_sold.d_dow IN (2, 3, 4)
  AND d_sold.d_fy_week_seq BETWEEN 8 AND 12
  AND inv.inv_quantity_on_hand > 100
GROUP BY d_sold.d_year, d_sold.d_month_seq, p.p_channel_dmail
ORDER BY total_net_profit DESC
LIMIT 100
