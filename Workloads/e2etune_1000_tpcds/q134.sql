WITH cr_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        SUM(cr.cr_refunded_cash) AS total_cr_refunded_cash,
        SUM(cr.cr_return_quantity) AS total_cr_return_qty,
        COUNT(*) AS cr_return_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_refunded_customer_sk IN (6114601, 10425383, 4976801)
      AND cr.cr_return_amount > 500
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
),
ws_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        SUM(ws.ws_net_profit) AS total_ws_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales,
        COUNT(*) AS ws_sales_cnt
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451200
    GROUP BY sm.sm_ship_mode_id
),
wr_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        SUM(wr.wr_net_loss) AS total_wr_net_loss,
        SUM(wr.wr_refunded_cash) AS total_wr_refunded_cash,
        SUM(wr.wr_return_quantity) AS total_wr_return_qty,
        COUNT(*) AS wr_return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE wr.wr_return_amt > 200
    GROUP BY sm.sm_ship_mode_id
)
SELECT
    COALESCE(cr_agg.sm_ship_mode_id, ws_agg.sm_ship_mode_id, wr_agg.sm_ship_mode_id) AS ship_mode_id,
    COALESCE(cr_agg.sm_carrier, 'UNKNOWN') AS carrier,
    COALESCE(cr_agg.total_cr_net_loss, 0) AS catalog_net_loss,
    COALESCE(wr_agg.total_wr_net_loss, 0) AS web_return_net_loss,
    COALESCE(ws_agg.total_ws_net_profit, 0) AS web_sales_net_profit,
    (COALESCE(cr_agg.total_cr_net_loss, 0) + COALESCE(wr_agg.total_wr_net_loss, 0)) AS total_return_loss,
    (COALESCE(cr_agg.total_cr_return_qty, 0) + COALESCE(wr_agg.total_wr_return_qty, 0)) AS total_return_qty,
    (COALESCE(cr_agg.cr_return_cnt, 0) + COALESCE(wr_agg.wr_return_cnt, 0)) AS total_return_cnt,
    COALESCE(ws_agg.total_ws_sales, 0) AS total_sales_amount
FROM cr_agg
FULL OUTER JOIN ws_agg ON cr_agg.sm_ship_mode_id = ws_agg.sm_ship_mode_id
FULL OUTER JOIN wr_agg ON COALESCE(cr_agg.sm_ship_mode_id, ws_agg.sm_ship_mode_id) = wr_agg.sm_ship_mode_id
WHERE (COALESCE(cr_agg.total_cr_net_loss, 0) + COALESCE(wr_agg.total_wr_net_loss, 0)) > 1000
ORDER BY total_return_loss DESC
LIMIT 100
