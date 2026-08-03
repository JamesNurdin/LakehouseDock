WITH ws_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_profit,
        ARRAY_AGG(DISTINCT ws.ws_ship_hdemo_sk) AS ship_hdemo_arr
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ext_sales_price > 1000
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
first_part AS (
    SELECT
        wagg.w_warehouse_name,
        hd AS ship_hdemo,
        wagg.total_profit
    FROM ws_agg wagg
    CROSS JOIN UNNEST(wagg.ship_hdemo_arr) AS t(hd)
    WHERE hd NOT IN (
        SELECT ws_ship_hdemo_sk FROM web_sales WHERE ws_coupon_amt > 500
    )
),
second_part AS (
    SELECT
        w.w_warehouse_name,
        ws.ws_ship_hdemo_sk AS ship_hdemo,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ext_wholesale_cost < 2000
      AND w.w_state = 'CA'
    GROUP BY w.w_warehouse_name, ws.ws_ship_hdemo_sk
),
unioned AS (
    SELECT w_warehouse_name, ship_hdemo, total_profit FROM first_part
    UNION
    SELECT w_warehouse_name, ship_hdemo, total_profit FROM second_part
)
SELECT
    w_warehouse_name,
    ship_hdemo,
    SUM(total_profit) AS sum_profit
FROM unioned
GROUP BY GROUPING SETS (
    (w_warehouse_name),
    (ship_hdemo),
    ()
)
ORDER BY sum_profit DESC
LIMIT 100
