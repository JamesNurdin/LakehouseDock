WITH base AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_store_credit,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        ws.ws_bill_hdemo_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_order_number,
        wr.wr_return_quantity,
        t.t_hour,
        CASE WHEN cr.cr_store_credit > 300 THEN 'High' ELSE 'Low' END AS credit_category
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE cr.cr_warehouse_sk IN (3, 7, 12)
      AND cr.cr_store_credit > 100
      AND ws.ws_bill_hdemo_sk = 3319
      AND ws.ws_net_paid_inc_tax BETWEEN 500 AND 2000
      AND wr.wr_return_quantity >= 10
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    cr_warehouse_sk,
    t_hour,
    credit_category,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(ws_net_paid_inc_tax) AS avg_sales,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    MIN(wr_return_quantity) AS min_return_qty,
    MAX(cr_store_credit) AS max_store_credit,
    SUM(SUM(cr_return_amount)) OVER (
        PARTITION BY cr_warehouse_sk
        ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_return_amount
FROM base
GROUP BY cr_warehouse_sk, t_hour, credit_category
ORDER BY total_return_amount DESC
LIMIT 100
