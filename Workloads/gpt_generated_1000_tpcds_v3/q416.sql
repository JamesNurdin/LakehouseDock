WITH qualified_warehouses AS (
    SELECT w.w_warehouse_sk,
           w.w_warehouse_name
    FROM warehouse w
    LEFT JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
    HAVING COUNT(*) > 10
),
combined_returns AS (
    SELECT
        r.r_reason_desc        AS reason_desc,
        'Catalog'              AS source,
        cr.cr_return_amount    AS return_amount,
        cr.cr_warehouse_sk     AS warehouse_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN qualified_warehouses qw ON cr.cr_warehouse_sk = qw.w_warehouse_sk
    WHERE cr.cr_return_amount > 0
      AND EXISTS (
            SELECT 1
            FROM call_center cc
            WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
              AND cc.cc_employees > 5
          )

    UNION ALL

    SELECT
        r.r_reason_desc        AS reason_desc,
        'Web'                  AS source,
        wr.wr_return_amt       AS return_amount,
        ws.ws_warehouse_sk     AS warehouse_sk
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN qualified_warehouses qw ON ws.ws_warehouse_sk = qw.w_warehouse_sk
    WHERE wr.wr_return_amt > 0
),
agg_returns AS (
    SELECT
        reason_desc,
        source,
        SUM(return_amount) AS total_return_amount,
        COUNT(*)          AS return_count
    FROM combined_returns
    GROUP BY reason_desc, source
    HAVING SUM(return_amount) > (
        SELECT AVG(return_amount) FROM combined_returns
    )
)
SELECT DISTINCT
    reason_desc,
    source,
    total_return_amount,
    return_count,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_return_amount DESC) AS rank_by_total,
    (SELECT AVG(total_return_amount) FROM agg_returns)                AS avg_total_return_amount
FROM agg_returns
ORDER BY source, rank_by_total
LIMIT 100
