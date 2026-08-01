WITH aggregated AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MAX(ws.ws_ext_sales_price) AS max_sale,
        inv_tot.total_qty_on_hand
    FROM
        web_sales ws
        JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN (
            SELECT
                inv_warehouse_sk,
                SUM(inv_quantity_on_hand) AS total_qty_on_hand
            FROM
                inventory
            WHERE
                inv_quantity_on_hand > 500
                AND inv_date_sk BETWEEN 2451040 AND 2451080
            GROUP BY
                inv_warehouse_sk
        ) inv_tot
            ON w.w_warehouse_sk = inv_tot.inv_warehouse_sk
    WHERE
        ws.ws_list_price > 50
        AND ws.ws_net_paid_inc_ship_tax BETWEEN 500 AND 4000
        AND w.w_street_type = 'Street'
        AND EXISTS (
            SELECT 1
            FROM inventory i
            WHERE i.inv_warehouse_sk = w.w_warehouse_sk
              AND i.inv_quantity_on_hand > 600
        )
    GROUP BY GROUPING SETS (
        (w.w_warehouse_id, w.w_city, w.w_warehouse_sk, inv_tot.total_qty_on_hand),
        (w.w_warehouse_id, w.w_city, w.w_warehouse_sk),
        (w.w_warehouse_id, w.w_city)
    )
)
SELECT
    w_warehouse_id,
    w_city,
    w_warehouse_sk,
    total_sales,
    avg_profit,
    order_cnt,
    max_sale,
    total_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY w_city ORDER BY total_sales DESC) AS city_warehouse_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
