WITH warehouse_profit AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
      AND cd.cd_marital_status = 'M'
      AND sm.sm_type = 'AIR'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    wp.w_warehouse_sk AS entity_key,
    wp.w_warehouse_name AS entity_name,
    'Catalog' AS source_type,
    wp.total_profit,
    wp.avg_profit,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_profit
FROM warehouse_profit wp

UNION ALL

SELECT
    ss.ss_store_sk AS entity_key,
    CONCAT('Store_', CAST(ss.ss_store_sk AS VARCHAR)) AS entity_name,
    'Store' AS source_type,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_net_profit) AS avg_profit,
    (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2) AS overall_avg_profit
FROM store_sales ss
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_education_status = 'Advanced Degree'
  AND cd.cd_marital_status = 'M'
GROUP BY ss.ss_store_sk
ORDER BY total_profit DESC
LIMIT 100
