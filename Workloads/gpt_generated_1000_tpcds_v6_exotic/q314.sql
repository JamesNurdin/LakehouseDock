WITH
    daytime_sales AS (
        SELECT DISTINCT
            ws.ws_bill_customer_sk,
            ws.ws_warehouse_sk,
            ws.ws_quantity,
            ws.ws_net_paid,
            ws.ws_sold_time_sk
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        WHERE td.t_hour BETWEEN 9 AND 17
    ),
    daytime_returns AS (
        SELECT DISTINCT
            cr.cr_returning_customer_sk AS customer_sk,
            cr.cr_warehouse_sk AS warehouse_sk,
            cr.cr_return_quantity AS quantity,
            cr.cr_return_amount AS return_amount,
            cr.cr_returned_time_sk AS time_sk
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        WHERE td.t_hour BETWEEN 9 AND 17
    ),
    combined AS (
        SELECT
            ws_bill_customer_sk AS customer_sk,
            ws_warehouse_sk AS warehouse_sk,
            ws_quantity AS quantity,
            ws_net_paid AS net_amount
        FROM daytime_sales
        UNION ALL
        SELECT
            customer_sk,
            warehouse_sk,
            quantity,
            -return_amount AS net_amount
        FROM daytime_returns
    )
SELECT
    c.c_customer_id,
    w.w_warehouse_name,
    CASE WHEN combined.quantity > 5 THEN 'High' ELSE 'Low' END AS qty_category,
    SUM(combined.net_amount) AS total_amount
FROM combined
JOIN customer c ON combined.customer_sk = c.c_customer_sk
JOIN warehouse w ON combined.warehouse_sk = w.w_warehouse_sk
GROUP BY
    c.c_customer_id,
    w.w_warehouse_name,
    CASE WHEN combined.quantity > 5 THEN 'High' ELSE 'Low' END
ORDER BY total_amount DESC
LIMIT 100
