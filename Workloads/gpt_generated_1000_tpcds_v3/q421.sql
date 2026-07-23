WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        w.w_warehouse_id,
        w.w_warehouse_sk,
        cp.cp_catalog_number,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450870 AND 2450900
      AND cp.cp_catalog_number IN (9, 12, 17)
      AND ca.ca_street_type = 'Boulevard'
    GROUP BY
        cc.cc_call_center_id,
        w.w_warehouse_id,
        w.w_warehouse_sk,
        cp.cp_catalog_number,
        sm.sm_type
),
inventory_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    sa.cc_call_center_id,
    w.w_state,
    COUNT(DISTINCT sa.w_warehouse_id) AS num_warehouses,
    SUM(sa.total_sales) AS call_center_total_sales,
    AVG(sa.total_sales) AS avg_warehouse_sales,
    SUM(sa.total_discount) / NULLIF(SUM(sa.total_sales), 0) AS discount_rate,
    (SELECT AVG(total_sales) FROM sales_agg) AS overall_avg_warehouse_sales,
    ia.total_inventory_qty
FROM sales_agg sa
JOIN warehouse w ON sa.w_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg ia ON w.w_warehouse_sk = ia.inv_warehouse_sk
WHERE sa.total_quantity > 100
  AND w.w_state = 'CA'
  AND ia.total_inventory_qty > 0
GROUP BY
    sa.cc_call_center_id,
    w.w_state,
    ia.total_inventory_qty
HAVING SUM(sa.total_sales) > 10000
ORDER BY call_center_total_sales DESC
LIMIT 100
