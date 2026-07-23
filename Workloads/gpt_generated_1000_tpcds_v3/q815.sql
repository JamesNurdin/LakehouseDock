WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(*) AS inventory_item_cnt
    FROM inventory
    WHERE inv_quantity_on_hand > 500
      AND inv_item_sk IN (101437, 101419, 101426)
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_state,
    w.w_gmt_offset,
    inv_agg.total_quantity_on_hand,
    inv_agg.inventory_item_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(cs.cs_ext_sales_price) AS min_sales,
    MAX(cs.cs_ext_sales_price) AS max_sales
FROM catalog_sales cs
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_gmt_offset = -5.00
  AND w.w_state = 'CA'
  AND cs.cs_ext_wholesale_cost > 1000.00
  AND cs.cs_ship_customer_sk IN (4098294, 2922254)
  AND cs.cs_quantity >= 2
  AND EXISTS (
      SELECT 1
      FROM inventory i
      WHERE i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_quantity_on_hand > 800
  )
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_state,
    w.w_gmt_offset,
    inv_agg.total_quantity_on_hand,
    inv_agg.inventory_item_cnt
HAVING SUM(cs.cs_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 100
