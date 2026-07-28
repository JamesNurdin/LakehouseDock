WITH ws_filtered AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        td.t_shift,
        td.t_hour
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'MORNING'
      AND td.t_hour BETWEEN 6 AND 12
)
SELECT
    w.w_warehouse_id,
    concat(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_display,
    regexp_extract(w.w_street_name, '^([^ ]+)', 1) AS street_prefix,
    sum(ws.ws_net_profit) AS total_net_profit,
    avg(inv.inv_quantity_on_hand) AS avg_on_hand_qty
FROM ws_filtered ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_item_sk = ws.ws_item_sk
WHERE regexp_like(w.w_street_name, '(Park|Elm)')
  AND w.w_city LIKE 'A%'
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_street_name
ORDER BY total_net_profit DESC
LIMIT 10
