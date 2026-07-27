WITH filtered_sales AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_order_number,
        wp.wp_rec_start_date,
        wh.w_state
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE wp.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
),
ship_mode_agg AS (
    SELECT
        sm.sm_ship_mode_id AS category_id,
        'ship_mode' AS category_type,
        SUM(fs.ws_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(DISTINCT fs.ws_order_number) AS order_count
    FROM filtered_sales fs
    JOIN ship_mode sm ON fs.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, 'ship_mode'
),
warehouse_state_agg AS (
    SELECT
        fs.w_state AS category_id,
        'warehouse_state' AS category_type,
        SUM(fs.ws_net_paid_inc_ship_tax) AS total_net_paid,
        COUNT(DISTINCT fs.ws_order_number) AS order_count
    FROM filtered_sales fs
    GROUP BY fs.w_state, 'warehouse_state'
)
SELECT
    category_id,
    category_type,
    total_net_paid,
    order_count
FROM (
    SELECT * FROM ship_mode_agg
    UNION ALL
    SELECT * FROM warehouse_state_agg
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
