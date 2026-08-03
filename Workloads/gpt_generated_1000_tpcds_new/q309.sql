WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        'SALES' AS metric,
        SUM(ws.ws_ext_sales_price) AS amount,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS category,
        LAG(SUM(ws.ws_ext_sales_price)) OVER (PARTITION BY sm.sm_carrier ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS lag_amount,
        NULL AS cum_amount
    FROM ship_mode sm
    JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ext_list_price > 3000
      AND sm.sm_carrier = 'UPS'
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
),
returns_agg_raw AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(wr.wr_return_amt) AS amount,
        CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'BIG' ELSE 'SMALL' END AS category
    FROM ship_mode sm
    JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_quantity > 2
      AND sm.sm_carrier = 'MSC'
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
),
returns_agg AS (
    SELECT
        sm_ship_mode_id,
        sm_carrier,
        'RETURNS' AS metric,
        amount,
        category,
        NULL AS lag_amount,
        SUM(amount) OVER (PARTITION BY sm_carrier ORDER BY amount ROWS UNBOUNDED PRECEDING) AS cum_amount
    FROM returns_agg_raw
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
LIMIT 100
