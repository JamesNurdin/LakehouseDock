WITH cat_sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(cs.cs_net_paid) AS cat_total_paid,
        SUM(cs.cs_net_profit) AS cat_total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS cat_order_cnt
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_warehouse_name
),
web_sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid) AS web_total_paid,
        SUM(ws.ws_net_profit) AS web_total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
returns_agg AS (
    SELECT
        w.w_warehouse_sk,
        SUM(cr.cr_return_quantity) AS ret_qty_total,
        SUM(cr.cr_return_amount) AS ret_amount_total,
        SUM(cr.cr_net_loss) AS ret_net_loss_total,
        COUNT(DISTINCT cr.cr_order_number) AS ret_order_cnt
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT
    ca.w_warehouse_id,
    ca.w_warehouse_name,
    ca.cat_total_paid,
    ca.cat_total_profit,
    ca.cat_order_cnt,
    ws.web_total_paid,
    ws.web_total_profit,
    ws.web_order_cnt,
    ra.ret_qty_total,
    ra.ret_amount_total,
    ra.ret_net_loss_total,
    ra.ret_order_cnt,
    CASE WHEN ca.cat_order_cnt > 0 THEN ra.ret_order_cnt * 1.0 / ca.cat_order_cnt ELSE NULL END AS return_order_rate
FROM cat_sales_agg ca
LEFT JOIN web_sales_agg ws
    ON ca.w_warehouse_sk = ws.w_warehouse_sk
LEFT JOIN returns_agg ra
    ON ca.w_warehouse_sk = ra.w_warehouse_sk
ORDER BY ca.w_warehouse_id
