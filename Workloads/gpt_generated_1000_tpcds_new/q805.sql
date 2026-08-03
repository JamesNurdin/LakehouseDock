WITH sales_ship AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_sold_time_sk,
        sm.sm_ship_mode_id,
        sm.sm_type
    FROM web_sales ws
    RIGHT OUTER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
filtered1 AS (
    SELECT ss.ws_order_number,
           ss.ws_item_sk
    FROM sales_ship ss
    WHERE ss.ws_quantity > 5
      AND EXISTS (
          SELECT 1
          FROM time_dim td
          WHERE td.t_time_sk = ss.ws_sold_time_sk
            AND td.t_hour BETWEEN 9 AND 17
      )
),
filtered2 AS (
    SELECT ss.ws_order_number,
           ss.ws_item_sk
    FROM sales_ship ss
    WHERE ss.ws_net_paid > 1000
      AND ss.sm_type = 'AIR'
)
SELECT
    COUNT(DISTINCT i.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT i.ws_item_sk) AS distinct_items
FROM (
    SELECT ws_order_number, ws_item_sk FROM filtered1
    INTERSECT
    SELECT ws_order_number, ws_item_sk FROM filtered2
) i
LIMIT 100
