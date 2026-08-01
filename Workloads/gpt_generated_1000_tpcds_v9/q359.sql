WITH high_cost AS (
    SELECT
        w.w_warehouse_sk AS warehouse_sk,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        'HighCost' AS cost_category,
        CASE WHEN EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
            WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
              AND i2.i_wholesale_cost > 1.0
              AND i2.i_units = 'Gross'
            LIMIT 1
        ) THEN true ELSE false END AS has_gross_units
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 1.0
      AND i.i_units IN ('Each', 'Bunch', 'Gross')
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
low_cost AS (
    SELECT
        w.w_warehouse_sk AS warehouse_sk,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        'LowCost' AS cost_category,
        CASE WHEN EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
            WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
              AND i2.i_wholesale_cost <= 1.0
              AND i2.i_units = 'Gross'
            LIMIT 1
        ) THEN true ELSE false END AS has_gross_units
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost <= 1.0
      AND i.i_units IN ('Each', 'Bunch', 'Gross')
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    warehouse_sk,
    w_warehouse_name,
    total_net_profit,
    cost_category,
    has_gross_units
FROM high_cost
UNION ALL
SELECT
    warehouse_sk,
    w_warehouse_name,
    total_net_profit,
    cost_category,
    has_gross_units
FROM low_cost
ORDER BY total_net_profit DESC
LIMIT 100
