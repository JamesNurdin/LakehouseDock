WITH cat_sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
    WHERE cs_net_paid > 0
)
SELECT
    cp.cp_catalog_page_id,
    CONCAT(cp.cp_department, ':', cp.cp_type) AS dept_type,
    sm.sm_ship_mode_id AS ship_mode,
    w.w_warehouse_name,
    regexp_extract(cp.cp_description, '(\\d+)', 1) AS extracted_number,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_quantity,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    (
        SELECT SUM(inv.inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
    ) AS total_inventory_on_hand,
    COUNT(DISTINCT time_dim.t_hour) AS distinct_hours_sold
FROM cat_sales_sample cs
JOIN time_dim ON cs.cs_sold_time_sk = time_dim.t_time_sk
CROSS JOIN LATERAL (
    SELECT cp.cp_catalog_page_id,
           cp.cp_department,
           cp.cp_type,
           cp.cp_description,
           cp.cp_catalog_page_sk
    FROM catalog_page cp
    WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
      AND regexp_like(cp.cp_description, '(?i)sale')
) AS cp
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cp.cp_description LIKE '%discount%'
  AND time_dim.t_shift = 'Evening'
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    w.w_warehouse_sk,
    regexp_extract(cp.cp_description, '(\\d+)', 1)
ORDER BY total_net_paid DESC
LIMIT 100
