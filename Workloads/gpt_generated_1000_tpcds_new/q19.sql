WITH wh_inv AS (
    SELECT w.w_warehouse_sk,
           w.w_city,
           i.inv_quantity_on_hand
    FROM warehouse w
    FULL OUTER JOIN inventory i
      ON w.w_warehouse_sk = i.inv_warehouse_sk
)
SELECT key,
       city,
       qty,
       src
FROM (
    SELECT ws.ws_order_number AS key,
           w.w_city AS city,
           ws.ws_quantity AS qty,
           'sales' AS src
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_current_quarter = 'Y'
      AND ws.ws_quantity > (SELECT MAX(inv_quantity_on_hand) FROM inventory)
    UNION ALL
    SELECT CAST(NULL AS integer) AS key,
           wh_inv.w_city AS city,
           wh_inv.inv_quantity_on_hand AS qty,
           'inventory' AS src
    FROM wh_inv
    WHERE wh_inv.inv_quantity_on_hand < (SELECT MAX(inv_quantity_on_hand) FROM inventory)
) AS combined
ORDER BY qty DESC
LIMIT 100
