WITH inv_summary AS (
    SELECT
        avg(inv_quantity_on_hand) AS avg_inv_qty,
        sum(inv_quantity_on_hand) AS total_inv_qty
    FROM inventory
)
SELECT
    td.t_hour,
    td.t_meal_time,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
    inv.avg_inv_qty,
    inv.total_inv_qty
FROM web_sales ws
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
CROSS JOIN inv_summary inv
WHERE td.t_hour BETWEEN 0 AND 4
  AND ws.ws_quantity > 2
  AND ws.ws_ext_discount_amt > 0
GROUP BY td.t_hour, td.t_meal_time, inv.avg_inv_qty, inv.total_inv_qty
ORDER BY total_net_profit DESC
LIMIT 10
