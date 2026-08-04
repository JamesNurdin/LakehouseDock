WITH sampled_inv AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),

cat_qty_a AS (
    SELECT i.i_category AS category,
           SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM sampled_inv inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1211
    GROUP BY i.i_category
    HAVING SUM(inv.inv_quantity_on_hand) > 500
),

cat_qty_b AS (
    SELECT i.i_category AS category,
           SUM(inv.inv_quantity_on_hand) AS total_qty
    FROM sampled_inv inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND inv.inv_warehouse_sk = 1
    GROUP BY i.i_category
    HAVING SUM(inv.inv_quantity_on_hand) > 300
),

union_cats AS (
    SELECT category, total_qty FROM cat_qty_a
    UNION ALL
    SELECT category, total_qty FROM cat_qty_b
),

intersect_items AS (
    SELECT i.i_item_sk
    FROM sampled_inv inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_brand = 'esecallyable'
    INTERSECT
    SELECT i.i_item_sk
    FROM sampled_inv inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_color = 'red'
),

except_items AS (
    SELECT i.i_item_sk
    FROM sampled_inv inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_manufact = 'antiablecally'
    EXCEPT
    SELECT i.i_item_sk
    FROM sampled_inv inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_brand = 'barprically'
),

item_cat AS (
    SELECT i_item_sk, i_category
    FROM item
),

full_join_agg AS (
    SELECT u.category,
           u.total_qty,
           ic.i_item_sk
    FROM union_cats u
    FULL OUTER JOIN item_cat ic ON u.category = ic.i_category
)
SELECT fu.category,
       fu.total_qty,
       fu.i_item_sk
FROM full_join_agg fu
WHERE fu.category IS NOT NULL OR fu.i_item_sk IS NOT NULL
ORDER BY fu.total_qty DESC NULLS LAST
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
