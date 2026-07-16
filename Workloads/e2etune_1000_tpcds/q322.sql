WITH warehouse_inventory AS (
    SELECT w.w_warehouse_id,
           w.w_warehouse_name,
           w.w_city,
           SUM(i.inv_quantity_on_hand) AS total_qty,
           COUNT(*) AS sku_count
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_city
    HAVING SUM(i.inv_quantity_on_hand) > 1000
),
preferred_customer_demo AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           COUNT(*) AS pref_cust_cnt,
           AVG(cd.cd_purchase_estimate) AS avg_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month IN (4, 12)
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
    HAVING COUNT(*) >= 10
)
SELECT 'warehouse' AS source,
       wi.w_warehouse_id AS id,
       wi.w_warehouse_name AS name,
       wi.w_city AS location,
       wi.total_qty,
       wi.sku_count,
       NULL AS gender,
       NULL AS marital_status,
       NULL AS pref_cust_cnt,
       NULL AS avg_estimate
FROM warehouse_inventory wi
UNION ALL
SELECT 'demographic' AS source,
       CAST(pcd.cd_demo_sk AS VARCHAR) AS id,
       NULL AS name,
       NULL AS location,
       NULL AS total_qty,
       NULL AS sku_count,
       pcd.cd_gender AS gender,
       pcd.cd_marital_status AS marital_status,
       pcd.pref_cust_cnt,
       pcd.avg_estimate
FROM preferred_customer_demo pcd
ORDER BY source, id
LIMIT 200
