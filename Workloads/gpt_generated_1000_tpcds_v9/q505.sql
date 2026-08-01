WITH intersected_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
    INTERSECT
    SELECT i.i_item_sk AS item_sk
    FROM item i
    WHERE i.i_current_price > 1000
),
warehouse_sales AS (
    SELECT w.w_warehouse_sk,
           w.w_warehouse_name,
           SUM(cs.cs_net_paid) AS total_net_paid,
           COUNT(*) AS sales_cnt,
           (
               SELECT MAX(cs3.cs_ext_discount_amt)
               FROM catalog_sales cs3
               WHERE cs3.cs_warehouse_sk = w.w_warehouse_sk
           ) AS max_discount,
           (
               SELECT SUM(cs4.cs_net_paid)
               FROM catalog_sales cs4
               WHERE cs4.cs_warehouse_sk = w.w_warehouse_sk
           ) AS total_sales_all_time
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN intersected_items ii ON cs.cs_item_sk = ii.item_sk
    WHERE cs.cs_ext_discount_amt > (
        SELECT AVG(cs5.cs_ext_discount_amt)
        FROM catalog_sales cs5
    )
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
    HAVING SUM(cs.cs_net_paid) > 50000
)
SELECT ws.w_warehouse_name,
       ws.total_net_paid,
       ws.sales_cnt,
       ws.max_discount,
       ws.total_sales_all_time
FROM warehouse_sales ws
ORDER BY ws.total_net_paid DESC
LIMIT 100
