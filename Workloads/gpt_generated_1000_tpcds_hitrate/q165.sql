WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_net_paid_inc_ship,
        ws.ws_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        t.t_hour,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_state,
        w.w_suite_number
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN catalog_returns cr
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND w.w_state = 'CA'
      AND w.w_suite_number NOT LIKE 'Suite 0%'
      AND ws.ws_net_paid_inc_ship > 1000
)
SELECT
    sr.w_warehouse_id,
    sr.w_warehouse_name,
    SUM(COALESCE(sr.cr_net_loss, 0) + COALESCE(sr.wr_net_loss, 0)) AS total_loss,
    CASE
        WHEN SUM(COALESCE(sr.cr_net_loss, 0) + COALESCE(sr.wr_net_loss, 0)) > 10000 THEN 'High'
        ELSE 'Low'
    END AS loss_category,
    RANK() OVER (ORDER BY SUM(COALESCE(sr.cr_net_loss, 0) + COALESCE(sr.wr_net_loss, 0)) DESC) AS loss_rank
FROM sales_returns sr
GROUP BY sr.w_warehouse_id, sr.w_warehouse_name
ORDER BY loss_rank
LIMIT 100
