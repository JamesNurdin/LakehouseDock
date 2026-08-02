WITH
sales_data AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_category AS category,
        'sale' AS trans_type,
        SUM(ss.ss_net_paid) AS amount,
        MAX(i.i_product_name) AS product_name
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '(?i)premium')
      AND i.i_color LIKE 'Red%'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category
),
returns_data AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_category AS category,
        'return' AS trans_type,
        SUM(cr.cr_net_loss) AS amount,
        MAX(i.i_product_name) AS product_name
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '(?i)premium')
      AND i.i_color LIKE 'Red%'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category
),
union_data AS (
    SELECT item_sk, item_id, category, trans_type, amount, product_name
    FROM sales_data
    UNION
    SELECT item_sk, item_id, category, trans_type, amount, product_name
    FROM returns_data
),
sales_items AS (
    SELECT DISTINCT item_id FROM sales_data
),
return_items AS (
    SELECT DISTINCT item_id FROM returns_data
),
items_no_returns AS (
    SELECT item_id FROM sales_items
    EXCEPT
    SELECT item_id FROM return_items
)
SELECT
    u.item_id,
    u.category,
    u.trans_type,
    SUM(u.amount) AS total_amount,
    MAX(u.product_name) AS product_name,
    CONCAT(u.category, '-', u.trans_type) AS cat_trans,
    MAX(REGEXP_EXTRACT(u.item_id, '([0-9]+)')) AS numeric_id_part,
    MAX(SUBSTR(u.item_id, 1, 5)) AS item_id_prefix,
    (SELECT AVG(i2.i_current_price)
       FROM item i2
       WHERE i2.i_category = u.category) AS avg_category_price
FROM union_data u
WHERE u.item_id IN (SELECT item_id FROM items_no_returns)
GROUP BY GROUPING SETS (
    (u.item_id, u.category, u.trans_type),
    (u.category, u.trans_type),
    (u.trans_type),
    ()
)
ORDER BY u.category ASC, u.item_id ASC, u.trans_type ASC
LIMIT 100
