WITH filtered AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        ws.ws_ext_wholesale_cost,
        ws.ws_net_profit,
        w.w_state,
        w.w_gmt_offset,
        w.w_county
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_catalog_number IN (101, 202)
      AND cp.cp_end_date_sk BETWEEN 2450904 AND 2451270
      AND w.w_gmt_offset = -6.00
      AND w.w_county = 'Franklin Parish'
      AND cr.cr_return_amount > 100.00
      AND ws.ws_ext_wholesale_cost > 500.00
)
SELECT
    w_state,
    cp_department,
    COUNT(DISTINCT cr_order_number) AS distinct_return_orders,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(ws_ext_wholesale_cost) AS avg_wholesale_cost,
    SUM(ws_net_profit) AS total_net_profit,
    MIN(ws_ext_wholesale_cost) AS min_wholesale_cost,
    MAX(ws_ext_wholesale_cost) AS max_wholesale_cost
FROM filtered
GROUP BY w_state, cp_department
ORDER BY total_return_amount DESC
LIMIT 100
