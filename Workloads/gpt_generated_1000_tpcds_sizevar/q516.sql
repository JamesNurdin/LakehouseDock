WITH sampled_sales AS (
    SELECT cs_item_sk
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
sampled_inventory AS (
    SELECT inv_item_sk
    FROM inventory TABLESAMPLE BERNOULLI (5)
    WHERE inv_quantity_on_hand > 0
),
common_items AS (
    SELECT cs_item_sk AS item_sk
    FROM sampled_sales
    INTERSECT
    SELECT inv_item_sk
    FROM sampled_inventory
),
promo_items AS (
    SELECT p_item_sk
    FROM promotion
    WHERE p_purpose = 'Unknown'
      AND p_start_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
),
final_set AS (
    SELECT i.i_item_id, i.i_product_name
    FROM item i
    JOIN common_items ci ON i.i_item_sk = ci.item_sk
    UNION ALL
    SELECT i.i_item_id, i.i_product_name
    FROM item i
    JOIN promo_items pi ON i.i_item_sk = pi.p_item_sk
)
SELECT f.i_item_id,
       f.i_product_name,
       m.d_month_seq,
       (
           SELECT COUNT(*)
           FROM web_returns wr
           WHERE wr.wr_item_sk = i.i_item_sk
       ) AS return_cnt
FROM final_set f
JOIN item i ON i.i_item_id = f.i_item_id
CROSS JOIN (
    SELECT d_month_seq
    FROM date_dim
    WHERE d_year = 2001
    GROUP BY d_month_seq
    LIMIT 3
) m
ORDER BY f.i_item_id
LIMIT 100
