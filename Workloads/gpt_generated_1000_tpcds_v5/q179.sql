WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    WHERE cs.cs_ship_hdemo_sk IN (6054, 6421, 6203, 5381)                       -- filter 1
      AND cs.cs_ext_sales_price > 1000                                          -- filter 2
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk
)
SELECT
    i.i_item_id,
    w.w_warehouse_name,
    sa.total_sales,
    sa.total_quantity,
    CASE
        WHEN inv.inv_quantity_on_hand > 500 THEN 'High Stock'
        WHEN inv.inv_quantity_on_hand BETWEEN 200 AND 500 THEN 'Medium Stock'
        ELSE 'Low Stock'
    END AS stock_level,
    RANK() OVER (PARTITION BY i.i_item_id ORDER BY sa.total_sales DESC) AS warehouse_sales_rank,
    (
        SELECT MAX(s2.total_sales)
        FROM sales_agg s2
        WHERE s2.cs_item_sk = i.i_item_sk
    ) AS max_sales_for_item,
    (sa.total_sales / (
        SELECT MAX(s3.total_sales)
        FROM sales_agg s3
        WHERE s3.cs_item_sk = i.i_item_sk
    )) * 100 AS sales_pct_of_max
FROM sales_agg sa
JOIN item i ON sa.cs_item_sk = i.i_item_sk
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_class_id IN (15, 7, 8, 6)                           -- filter 3
  AND i.i_wholesale_cost BETWEEN 0.5 AND 60                     -- filter 4
  AND w.w_state = 'CA'                                          -- additional filter
ORDER BY i.i_item_id, warehouse_sales_rank
LIMIT 100
