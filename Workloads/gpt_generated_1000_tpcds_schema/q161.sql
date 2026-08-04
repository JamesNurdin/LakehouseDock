-- goal: compute total sales and total inventory on hand per item category for items whose manufacturer name is all lowercase and whose formulation contains digits, showing a combined category-number label, and keep only categories with sales above the overall average.
WITH item_inventory AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_formulation,
        i.i_manufact,
        inv.inv_quantity_on_hand,
        inv.inv_warehouse_sk
    FROM item i
    FULL OUTER JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
)
SELECT
    ii.i_category,
    regexp_extract(ii.i_formulation, '(\\d+)', 1) AS first_number,
    CONCAT(ii.i_category, '-', regexp_extract(ii.i_formulation, '(\\d+)', 1)) AS cat_num,
    SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
    SUM(COALESCE(ii.inv_quantity_on_hand, 0)) AS total_on_hand,
    COUNT(DISTINCT ss.ss_store_sk) AS stores_selling
FROM item_inventory ii
LEFT JOIN store_sales ss
    ON ii.i_item_sk = ss.ss_item_sk
WHERE regexp_like(ii.i_manufact, '^[a-z]{5,}$')
  AND ii.i_category LIKE 'Food%'
GROUP BY
    ii.i_category,
    regexp_extract(ii.i_formulation, '(\\d+)', 1)
HAVING
    SUM(COALESCE(ss.ss_ext_sales_price, 0)) > (
        SELECT AVG(ss2.ss_ext_sales_price) FROM store_sales ss2
    )
ORDER BY total_sales DESC
LIMIT 100
