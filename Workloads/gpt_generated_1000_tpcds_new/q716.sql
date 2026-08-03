WITH sales_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    sm.sm_type AS category_name,
    d.d_date AS activity_date,
    SUM(ws.ws_quantity) AS metric_quantity,
    SUM(CAST(ws.ws_net_paid AS double)) AS metric_amount,
    SUM(rc.return_cnt) AS return_cnt,
    'sales' AS source
FROM sales_sample ws
RIGHT JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN LATERAL (
        SELECT ARRAY[ws.ws_item_sk, ws.ws_quantity] AS arr
) a ON true
LEFT JOIN UNNEST(a.arr) AS t(unnested_val) ON true
LEFT JOIN LATERAL (
        SELECT COUNT(*) AS return_cnt
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
) rc ON true
WHERE d.d_current_year = 'Y'
GROUP BY sm.sm_type, d.d_date

UNION

SELECT
    w.w_warehouse_name AS category_name,
    d.d_date AS activity_date,
    SUM(i.inv_quantity_on_hand) AS metric_quantity,
    CAST(NULL AS double) AS metric_amount,
    CAST(NULL AS integer) AS return_cnt,
    'inventory' AS source
FROM inventory i
TABLESAMPLE BERNOULLI (10)
RIGHT JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
WHERE d.d_current_year = 'Y'
GROUP BY w.w_warehouse_name, d.d_date

ORDER BY activity_date DESC, category_name
LIMIT 100
