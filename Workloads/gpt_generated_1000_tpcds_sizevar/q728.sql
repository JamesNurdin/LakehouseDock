WITH
    catalog_cte AS (
        SELECT
            cs.cs_sold_time_sk,
            cs.cs_warehouse_sk AS warehouse_sk,
            cs.cs_item_sk,
            cs.cs_net_paid_inc_ship,
            cs.cs_list_price,
            w.w_warehouse_name,
            t.t_hour
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    ),
    store_cte AS (
        SELECT
            ss.ss_sold_time_sk,
            ss.ss_item_sk,
            ss.ss_ticket_number,
            ss.ss_net_paid,
            ss.ss_net_profit,
            t2.t_hour,
            sr.sr_return_quantity,
            sr.sr_net_loss
        FROM store_sales ss
        RIGHT JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
        LEFT JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_ticket_number = ss.ss_ticket_number
    ),
    web_cte AS (
        SELECT
            ws.ws_sold_time_sk,
            ws.ws_item_sk,
            ws.ws_order_number,
            ws.ws_net_paid,
            ws.ws_net_profit,
            t3.t_hour,
            wr.wr_return_quantity,
            wr.wr_net_loss
        FROM web_sales ws
        JOIN warehouse w3 ON ws.ws_warehouse_sk = w3.w_warehouse_sk
        JOIN time_dim t3 ON ws.ws_sold_time_sk = t3.t_time_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = ws.ws_item_sk
           AND wr.wr_order_number = ws.ws_order_number
    ),
    union_cte AS (
        SELECT
            ss_sold_time_sk AS time_sk,
            ss_item_sk AS item_sk,
            ss_ticket_number AS order_number,
            ss_net_paid AS net_paid,
            ss_net_profit AS net_profit,
            t_hour,
            COALESCE(sr_return_quantity, 0) AS return_qty,
            COALESCE(sr_net_loss, 0) AS net_loss,
            'store' AS channel
        FROM store_cte
        UNION DISTINCT
        SELECT
            ws_sold_time_sk,
            ws_item_sk,
            ws_order_number,
            ws_net_paid,
            ws_net_profit,
            t_hour,
            COALESCE(wr_return_quantity, 0),
            COALESCE(wr_net_loss, 0),
            'web' AS channel
        FROM web_cte
    ),
    intersect_cte AS (
        SELECT time_sk FROM union_cte WHERE net_profit > 0
        INTERSECT
        SELECT cs_sold_time_sk FROM catalog_cte WHERE cs_list_price > 100
    ),
    final AS (
        SELECT
            uc.time_sk,
            uc.item_sk,
            uc.order_number,
            uc.channel,
            uc.net_paid,
            uc.net_profit,
            uc.return_qty,
            uc.net_loss,
            ic.t_hour,
            ic.w_warehouse_name,
            lt.warehouse_total,
            ROW_NUMBER() OVER (PARTITION BY uc.channel ORDER BY uc.net_profit DESC) AS rnk
        FROM union_cte uc
        JOIN intersect_cte i ON uc.time_sk = i.time_sk
        JOIN catalog_cte ic ON uc.time_sk = ic.cs_sold_time_sk
        LEFT JOIN LATERAL (
            SELECT SUM(cs.cs_net_paid_inc_ship) AS warehouse_total
            FROM catalog_sales cs
            WHERE cs.cs_warehouse_sk = ic.warehouse_sk
        ) lt ON TRUE
        LEFT JOIN warehouse w4 ON ic.warehouse_sk = w4.w_warehouse_sk
    )
SELECT
    time_sk,
    item_sk,
    order_number,
    channel,
    net_paid,
    net_profit,
    return_qty,
    net_loss,
    t_hour,
    w_warehouse_name,
    warehouse_total
FROM final
WHERE rnk <= 5
ORDER BY net_profit DESC
LIMIT 100
