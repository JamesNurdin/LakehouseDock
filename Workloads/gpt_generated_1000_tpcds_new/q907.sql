WITH sales AS (
    SELECT
        c.c_customer_id,
        i.i_category,
        ss.ss_net_paid AS net_paid,
        ARRAY[i.i_brand, i.i_class] AS brand_class_arr
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_paid > 1000
),
returns AS (
    SELECT
        c.c_customer_id,
        i.i_category,
        cr.cr_return_amount AS return_amount,
        ARRAY[i.i_brand, i.i_class] AS brand_class_arr
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 0
),
union_sales_returns AS (
    SELECT c_customer_id, i_category, net_paid AS metric, brand_class_arr
    FROM sales
    UNION
    SELECT c_customer_id, i_category, return_amount AS metric, brand_class_arr
    FROM returns
),
inventory_expanded AS (
    SELECT
        w.w_warehouse_id,
        i.i_item_id,
        inv.inv_quantity_on_hand,
        bc AS brand_or_class
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(ARRAY[i.i_brand, i.i_class]) AS t(bc)
),
full_combined AS (
    SELECT
        u.c_customer_id,
        u.i_category,
        u.metric,
        inv.w_warehouse_id,
        inv.i_item_id,
        inv.inv_quantity_on_hand,
        inv.brand_or_class
    FROM union_sales_returns u
    FULL OUTER JOIN inventory_expanded inv
        ON u.i_category = inv.brand_or_class
),
sales_customers AS (
    SELECT DISTINCT c_customer_id FROM sales
),
return_customers AS (
    SELECT DISTINCT c_customer_id FROM returns
),
sales_not_return AS (
    SELECT c_customer_id FROM sales_customers
    EXCEPT
    SELECT c_customer_id FROM return_customers
)
SELECT
    fc.c_customer_id,
    fc.i_category,
    fc.metric,
    fc.w_warehouse_id,
    fc.i_item_id,
    fc.inv_quantity_on_hand,
    fc.brand_or_class
FROM full_combined fc
WHERE NOT EXISTS (
    SELECT 1 FROM returns r WHERE r.c_customer_id = fc.c_customer_id
)
  AND fc.c_customer_id IN (SELECT c_customer_id FROM sales_not_return)
ORDER BY fc.metric DESC
LIMIT 100
