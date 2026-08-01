WITH sales_by_warehouse AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        COALESCE(SUM(cs.cs_net_paid), 0) AS metric_value
    FROM catalog_sales cs
    RIGHT OUTER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_warehouse_name
),
returns_by_warehouse AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        COALESCE(SUM(cr.cr_net_loss), 0) AS metric_value
    FROM catalog_returns cr
    RIGHT OUTER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_warehouse_name
),
combined AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_id,
        w_warehouse_name,
        'sales'   AS metric_type,
        metric_value
    FROM sales_by_warehouse
    UNION ALL
    SELECT
        w_warehouse_sk,
        w_warehouse_id,
        w_warehouse_name,
        'returns' AS metric_type,
        metric_value
    FROM returns_by_warehouse
)
SELECT
    c.w_warehouse_id,
    c.w_warehouse_name,
    c.metric_type,
    c.metric_value,
    (
        SELECT SUM(inv.inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = c.w_warehouse_sk
    ) AS total_inventory,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = c.w_warehouse_sk
          AND cs2.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    ) AS sales_order_count
FROM combined c
WHERE c.metric_value > (
    SELECT AVG(metric_value)
    FROM combined
    WHERE metric_type = c.metric_type
)
ORDER BY c.w_warehouse_id, c.metric_type
LIMIT 100
