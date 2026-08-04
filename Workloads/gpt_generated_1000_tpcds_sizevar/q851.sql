/* Goal: Identify top‑selling items in a recent period and combine them with low‑inventory items that were not sold in that period, categorizing each row, deduplicating via UNION, and limiting to 100 rows. */
WITH low_inventory AS (
    SELECT inv_item_sk
    FROM inventory TABLESAMPLE BERNOULLI (10)
    WHERE inv_quantity_on_hand < 100
    EXCEPT
    SELECT cs_item_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451080 AND 2451095
),

sales_agg AS (
    SELECT i.i_item_id,
           i.i_product_name,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           CASE WHEN SUM(cs.cs_ext_sales_price) > 20000 THEN 'High' ELSE 'Medium' END AS category
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451080 AND 2451095
    GROUP BY i.i_item_id, i.i_product_name
),

inventory_sel AS (
    SELECT i.i_item_id,
           i.i_product_name,
           CAST(inv.inv_quantity_on_hand AS decimal(10,2)) AS metric,
           CASE WHEN inv.inv_quantity_on_hand < 50 THEN 'Low' ELSE 'Adequate' END AS category
    FROM low_inventory li
    JOIN inventory inv ON li.inv_item_sk = inv.inv_item_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE EXISTS (
        SELECT 1
        FROM call_center cc
        WHERE cc.cc_state = 'CA'               -- example predicate to illustrate a scalar sub‑query use case
          AND cc.cc_zip = '74593'
    )
)
SELECT item_id,
       product_name,
       metric,
       category
FROM (
    SELECT i_item_id AS item_id,
           i_product_name AS product_name,
           total_sales AS metric,
           category
    FROM sales_agg
    UNION
    SELECT i_item_id AS item_id,
           i_product_name AS product_name,
           metric,
           category
    FROM inventory_sel
) AS combined
ORDER BY metric DESC
LIMIT 100
