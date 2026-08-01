WITH ship_mode_agg AS (
    SELECT
        sm.sm_ship_mode_id AS category_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        'ShipMode' AS source_type,
        CAST(NULL AS integer) AS warehouse_sk
    FROM catalog_sales cs
    FULL OUTER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE (cs.cs_net_profit > 5000 OR cs.cs_net_profit IS NULL)
      AND (sm.sm_contract LIKE 'P%' OR sm.sm_contract IS NULL)
    GROUP BY sm.sm_ship_mode_id
),
warehouse_agg AS (
    SELECT
        w.w_warehouse_name AS category_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        'Warehouse' AS source_type,
        w.w_warehouse_sk AS warehouse_sk
    FROM catalog_sales cs
    FULL OUTER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE (w.w_warehouse_sq_ft > 500000 OR w.w_warehouse_sq_ft IS NULL)
      AND (cs.cs_quantity > 10 OR cs.cs_quantity IS NULL)
    GROUP BY w.w_warehouse_name, w.w_warehouse_sk
),
combined AS (
    SELECT * FROM ship_mode_agg
    UNION ALL
    SELECT * FROM warehouse_agg
)
SELECT
    combined.category_id,
    combined.source_type,
    combined.total_sales,
    combined.total_profit,
    combined.warehouse_sk,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = combined.warehouse_sk
          AND cs2.cs_ext_sales_price > combined.total_sales
    ) AS higher_sales_count
FROM combined
WHERE combined.total_sales > 10000
  AND (
        combined.warehouse_sk IS NULL
        OR combined.total_sales > (
            SELECT AVG(cs3.cs_ext_sales_price)
            FROM catalog_sales cs3
            WHERE cs3.cs_warehouse_sk = combined.warehouse_sk
        )
      )
ORDER BY combined.total_sales DESC
LIMIT 100
