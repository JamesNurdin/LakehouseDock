/* goal: Compare total net loss from catalog returns and web returns by warehouse state, combining the results with UNION ALL */
WITH catalog_loss AS (
    SELECT
        w.w_state AS state,
        'Catalog' AS source,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_amount > 100
      AND w.w_state IN ('MO', 'OH')
    GROUP BY w.w_state
),
web_loss AS (
    SELECT
        w.w_state AS state,
        'Web' AS source,
        SUM(wr.wr_net_loss) AS total_loss
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_amt > 100
      AND w.w_state IN ('MO', 'OH')
    GROUP BY w.w_state
)
SELECT state, source, total_loss
FROM catalog_loss
UNION ALL
SELECT state, source, total_loss
FROM web_loss
ORDER BY state, source
