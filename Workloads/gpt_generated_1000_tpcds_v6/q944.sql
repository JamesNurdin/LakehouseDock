WITH
    cr AS (
        SELECT
            w_cr.w_warehouse_id,
            w_cr.w_state,
            r_cr.r_reason_desc,
            t_cr.t_hour,
            SUM(cr.cr_net_loss) AS catalog_net_loss,
            COUNT(DISTINCT cr.cr_order_number) AS catalog_distinct_orders
        FROM tpcds.catalog_returns cr
        JOIN tpcds.catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN tpcds.warehouse w_cr
            ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
        JOIN tpcds.reason r_cr
            ON cr.cr_reason_sk = r_cr.r_reason_sk
        JOIN tpcds.time_dim t_cr
            ON cr.cr_returned_time_sk = t_cr.t_time_sk
        JOIN tpcds.customer c_ref
            ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
        JOIN tpcds.customer_demographics cd_ref
            ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        GROUP BY w_cr.w_warehouse_id, w_cr.w_state, r_cr.r_reason_desc, t_cr.t_hour
    ),
    sr AS (
        SELECT
            r_sr.r_reason_desc,
            t_sr.t_hour,
            SUM(sr.sr_net_loss) AS store_net_loss,
            COUNT(DISTINCT sr.sr_ticket_number) AS store_distinct_tickets
        FROM tpcds.store_returns sr
        JOIN tpcds.reason r_sr
            ON sr.sr_reason_sk = r_sr.r_reason_sk
        JOIN tpcds.time_dim t_sr
            ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN tpcds.customer c_sr
            ON sr.sr_customer_sk = c_sr.c_customer_sk
        JOIN tpcds.customer_demographics cd_sr
            ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        GROUP BY r_sr.r_reason_desc, t_sr.t_hour
    ),
    ws AS (
        SELECT
            w_ws.w_warehouse_id,
            w_ws.w_state,
            t_ws.t_hour,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(DISTINCT ws.ws_order_number) AS web_distinct_orders
        FROM tpcds.web_sales ws
        JOIN tpcds.warehouse w_ws
            ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        JOIN tpcds.time_dim t_ws
            ON ws.ws_sold_time_sk = t_ws.t_time_sk
        JOIN tpcds.customer c_ws
            ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
        JOIN tpcds.customer_demographics cd_ws
            ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
        GROUP BY w_ws.w_warehouse_id, w_ws.w_state, t_ws.t_hour
    )
SELECT
    COALESCE(cr.w_warehouse_id, ws.w_warehouse_id) AS warehouse_id,
    COALESCE(cr.w_state, ws.w_state) AS warehouse_state,
    COALESCE(cr.r_reason_desc, sr.r_reason_desc) AS reason_desc,
    COALESCE(cr.t_hour, sr.t_hour, ws.t_hour) AS hour_of_day,
    SUM(cr.catalog_net_loss) AS total_catalog_net_loss,
    SUM(sr.store_net_loss) AS total_store_net_loss,
    SUM(ws.web_net_profit) AS total_web_net_profit,
    SUM(cr.catalog_distinct_orders) AS total_catalog_distinct_orders,
    SUM(sr.store_distinct_tickets) AS total_store_distinct_tickets,
    SUM(ws.web_distinct_orders) AS total_web_distinct_orders
FROM cr
FULL OUTER JOIN sr
    ON cr.r_reason_desc = sr.r_reason_desc
   AND cr.t_hour = sr.t_hour
FULL OUTER JOIN ws
    ON COALESCE(cr.w_warehouse_id, ws.w_warehouse_id) = ws.w_warehouse_id
   AND COALESCE(cr.t_hour, sr.t_hour, ws.t_hour) = ws.t_hour
GROUP BY
    COALESCE(cr.w_warehouse_id, ws.w_warehouse_id),
    COALESCE(cr.w_state, ws.w_state),
    COALESCE(cr.r_reason_desc, sr.r_reason_desc),
    COALESCE(cr.t_hour, sr.t_hour, ws.t_hour)
ORDER BY total_web_net_profit DESC
LIMIT 100
