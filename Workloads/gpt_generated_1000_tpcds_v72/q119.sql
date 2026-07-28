WITH base AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        CASE
            WHEN cr.cr_return_amount > 1000 THEN 'HIGH_RETURN'
            ELSE 'LOW_RETURN'
        END AS return_level
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_sq_ft > 500000
      AND cr.cr_reversed_charge < 100
      AND ws.ws_ext_wholesale_cost BETWEEN 2000 AND 7000
),
agg1 AS (
    SELECT
        w_warehouse_id,
        w_city,
        w_state,
        return_level,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY ROLLUP (w_warehouse_id, w_city, w_state, return_level)
)
SELECT
    a.w_warehouse_id,
    a.w_city,
    a.w_state,
    a.return_level,
    a.total_return_amount,
    a.total_sales,
    a.total_profit,
    a.txn_count,
    a.total_sales / NULLIF(a.txn_count, 0) AS avg_sales_per_txn,
    (SELECT MAX(ws3.ws_order_number)
     FROM web_sales ws3
     JOIN warehouse w3 ON ws3.ws_warehouse_sk = w3.w_warehouse_sk
     WHERE w3.w_warehouse_id = a.w_warehouse_id) AS max_order_number
FROM agg1 a
WHERE NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN warehouse w2 ON ws2.ws_warehouse_sk = w2.w_warehouse_sk
        WHERE w2.w_warehouse_id = a.w_warehouse_id
          AND ws2.ws_coupon_amt > 500
      )
  AND a.total_return_amount > 0
  AND (a.total_sales / NULLIF(a.txn_count, 0)) > 3000
ORDER BY avg_sales_per_txn DESC
LIMIT 100
