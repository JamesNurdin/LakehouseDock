WITH call_center_sales AS (
    SELECT
        'call_center' AS src_type,
        cc.cc_name AS key_name,
        SUBSTR(cc.cc_name, 1, 3) AS key_prefix,
        COUNT(*) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = i.i_item_sk
        ) AS avg_profit_per_item
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '^[A-Z]{2}[0-9]{3}')
      AND cc.cc_state LIKE CONCAT('C', '%')
    GROUP BY cc.cc_name, i.i_item_sk
    HAVING COUNT(*) > 10
),
warehouse_sales AS (
    SELECT
        'warehouse' AS src_type,
        w.w_warehouse_name AS key_name,
        SUBSTR(w.w_warehouse_name, 1, 3) AS key_prefix,
        COUNT(*) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
        ) AS avg_profit_per_item
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_contract LIKE '%X%'
      AND EXISTS (
          SELECT 1
          FROM call_center cc2
          WHERE cc2.cc_call_center_sk = cs.cs_call_center_sk
            AND cc2.cc_city LIKE 'New%'
      )
    GROUP BY w.w_warehouse_name, w.w_warehouse_sk
    HAVING SUM(cs.cs_ext_ship_cost) > 1000
)
SELECT
    src_type,
    key_name,
    key_prefix,
    total_sales,
    total_profit,
    avg_profit_per_item
FROM call_center_sales
UNION ALL
SELECT
    src_type,
    key_name,
    key_prefix,
    total_sales,
    total_profit,
    avg_profit_per_item
FROM warehouse_sales
ORDER BY total_profit DESC
LIMIT 100
