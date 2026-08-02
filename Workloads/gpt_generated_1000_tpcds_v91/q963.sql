WITH sales_by_warehouse AS (
    SELECT 
        cs.cs_warehouse_sk,
        w.w_warehouse_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE 
            WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High'
            WHEN SUM(cs.cs_net_paid) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE sm.sm_code = 'AIR'
      AND td.t_hour BETWEEN 12 AND 18
      AND i.i_rec_start_date >= DATE '2000-01-01'
    GROUP BY cs.cs_warehouse_sk, w.w_warehouse_name
),
inventory_by_warehouse AS (
    SELECT
        inv.inv_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_manufact = 'callyable'
    GROUP BY inv.inv_warehouse_sk, w.w_warehouse_name
),
full_warehouse AS (
    SELECT
        COALESCE(s.cs_warehouse_sk, i.inv_warehouse_sk) AS warehouse_sk,
        COALESCE(s.w_warehouse_name, i.w_warehouse_name) AS warehouse_name,
        s.total_net_paid,
        i.total_quantity,
        s.sales_category,
        CASE 
            WHEN s.cs_warehouse_sk IS NOT NULL AND i.inv_warehouse_sk IS NOT NULL THEN 'Both'
            WHEN s.cs_warehouse_sk IS NOT NULL THEN 'Sales Only'
            WHEN i.inv_warehouse_sk IS NOT NULL THEN 'Inventory Only'
            ELSE 'None'
        END AS record_status
    FROM sales_by_warehouse s
    FULL OUTER JOIN inventory_by_warehouse i
        ON s.cs_warehouse_sk = i.inv_warehouse_sk
)
SELECT
    fw.warehouse_sk,
    fw.warehouse_name,
    fw.total_net_paid,
    fw.total_quantity,
    fw.sales_category,
    fw.record_status,
    CASE 
        WHEN fw.total_net_paid > 75000 THEN 'Hot Sales'
        ELSE 'Cold Sales'
    END AS tier_desc
FROM full_warehouse fw
WHERE fw.total_net_paid IS NOT NULL
UNION ALL
SELECT
    fw.warehouse_sk,
    fw.warehouse_name,
    fw.total_net_paid,
    fw.total_quantity,
    fw.sales_category,
    fw.record_status,
    CASE 
        WHEN fw.total_quantity > 5000 THEN 'Stock Rich'
        ELSE 'Stock Poor'
    END AS tier_desc
FROM full_warehouse fw
WHERE fw.total_quantity IS NOT NULL
ORDER BY warehouse_name, tier_desc
