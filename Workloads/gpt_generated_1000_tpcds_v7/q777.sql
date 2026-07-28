/* Goal: Combine aggregated sales and return metrics per warehouse and hour for promotions sent via email or direct mail, distinguishing the two record types. */
WITH sales_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        td.t_hour          AS hour,
        SUM(ws.ws_ext_sales_price) AS metric_amount,
        SUM(ws.ws_net_profit)      AS metric_profit,
        'sale'                     AS record_type
    FROM web_sales ws
    JOIN promotion p      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td      ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY w.w_warehouse_name, td.t_hour
),
returns_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        td.t_hour          AS hour,
        SUM(wr.wr_return_amt) AS metric_amount,
        SUM(wr.wr_net_loss)   AS metric_profit,
        'return'              AS record_type
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                      AND wr.wr_item_sk = ws.ws_item_sk
    JOIN promotion p   ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td   ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN warehouse w   ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_channel_dmail = 'Y'
    GROUP BY w.w_warehouse_name, td.t_hour
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
LIMIT 100
