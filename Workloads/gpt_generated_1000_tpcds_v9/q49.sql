WITH
cr AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_order_number,
        t.t_hour AS cr_hour,
        t.t_sub_shift AS cr_state,
        w.w_warehouse_name AS cr_warehouse_name
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        t.t_hour = 12
        AND t.t_sub_shift = 'morning'
        AND cr.cr_return_quantity > 10
        AND cr.cr_return_amount > 100.00
        AND w.w_state = 'CA'
),
ws AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_warehouse_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number,
        t.t_hour AS ws_hour,
        t.t_sub_shift AS ws_state,
        w.w_warehouse_name AS ws_warehouse_name
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        t.t_hour = 12
        AND t.t_sub_shift = 'morning'
        AND ws.ws_quantity >= 50
        AND ws.ws_net_profit > 0
        AND w.w_state = 'CA'
),
joined AS (
    SELECT
        COALESCE(cr.cr_warehouse_sk, ws.ws_warehouse_sk) AS warehouse_sk,
        COALESCE(cr.cr_warehouse_name, ws.ws_warehouse_name) AS warehouse_name,
        COALESCE(cr.cr_hour, ws.ws_hour) AS hour,
        COALESCE(cr.cr_state, ws.ws_state) AS state,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        cr.cr_order_number,
        ws.ws_order_number
    FROM cr
    FULL OUTER JOIN ws
        ON cr.cr_hour = ws.ws_hour
        AND cr.cr_state = ws.ws_state
        AND cr.cr_warehouse_sk = ws.ws_warehouse_sk
)
SELECT
    warehouse_sk,
    warehouse_name,
    hour,
    state,
    SUM(cr_return_quantity) AS total_return_qty,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_quantity) AS total_sales_qty,
    SUM(ws_net_paid) AS total_sales_net_paid,
    AVG(ws_net_profit) AS avg_sales_net_profit,
    COUNT(DISTINCT COALESCE(cr_order_number, ws_order_number)) AS distinct_orders,
    (
        SELECT SUM(c2.cr_return_amount)
        FROM catalog_returns c2
        WHERE c2.cr_warehouse_sk = warehouse_sk
    ) AS warehouse_total_return_amount
FROM joined
GROUP BY GROUPING SETS (
    (warehouse_sk, warehouse_name, hour, state),
    (warehouse_sk, warehouse_name, hour),
    (warehouse_sk, warehouse_name, state),
    (warehouse_sk, warehouse_name),
    (hour, state),
    (hour),
    (state),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
