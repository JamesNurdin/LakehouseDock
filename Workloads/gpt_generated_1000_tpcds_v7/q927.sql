WITH warehouse_avg AS (
        SELECT w.w_warehouse_sk,
               AVG(cs.cs_ext_sales_price) AS avg_sales_price
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_sk
    )
SELECT
    cc.cc_call_center_id,
    w.w_warehouse_name,
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    inv.inv_quantity_on_hand,
    CASE WHEN cs.cs_ext_sales_price > wa.avg_sales_price THEN 'Above Avg' ELSE 'Below Avg' END AS price_category,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank_by_center
FROM call_center cc
JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN warehouse_avg wa ON wa.w_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_ext_sales_price > 2000
  AND w.w_gmt_offset >= -6.00
  AND inv.inv_quantity_on_hand < 300
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = cs.cs_item_sk
          AND cs2.cs_ext_discount_amt > 0
    )
ORDER BY cc.cc_call_center_id, sales_rank_by_center
LIMIT 100
