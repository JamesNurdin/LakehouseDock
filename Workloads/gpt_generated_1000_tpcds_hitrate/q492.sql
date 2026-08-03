WITH sales AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_hour AS hour,
        SUM(ws.ws_net_paid_inc_tax) AS net_amount,
        'sale' AS record_type,
        CASE WHEN SUM(ws.ws_net_paid_inc_tax) > 10000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT DISTINCT ws2.ws_sold_date_sk
        FROM web_sales ws2
        WHERE ws2.ws_quantity > 5
    )
    GROUP BY sm.sm_ship_mode_id, td.t_hour
),
returns AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_hour AS hour,
        -SUM(wr.wr_return_amt_inc_tax) AS net_amount,
        'return' AS record_type,
        CASE WHEN SUM(wr.wr_return_amt_inc_tax) > 5000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT DISTINCT ws2.ws_sold_date_sk
        FROM web_sales ws2
        WHERE ws2.ws_quantity > 5
    )
    GROUP BY sm.sm_ship_mode_id, td.t_hour
)
SELECT
    ship_mode_id,
    hour,
    amount_category,
    SUM(net_amount) AS total_net_amount,
    CASE WHEN SUM(net_amount) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_indicator
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) combined
GROUP BY CUBE(ship_mode_id, hour, amount_category)
HAVING SUM(net_amount) IS NOT NULL
ORDER BY total_net_amount DESC
LIMIT 100
