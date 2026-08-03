WITH catalog_items AS (
    SELECT i.i_item_id,
           i.i_product_name
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cp.cp_department = 'Electronics'
      AND cs.cs_net_profit > 1000
),
store_items AS (
    SELECT i.i_item_id,
           i.i_product_name
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_division_id = 1
      AND ss.ss_net_profit > 1000
)
SELECT
    ROW_NUMBER() OVER (ORDER BY common.i_item_id) AS row_num,
    common.i_item_id,
    common.i_product_name
FROM (
    SELECT i_item_id, i_product_name FROM catalog_items
    INTERSECT
    SELECT i_item_id, i_product_name FROM store_items
) AS common
ORDER BY common.i_item_id
OFFSET 0
LIMIT 100
