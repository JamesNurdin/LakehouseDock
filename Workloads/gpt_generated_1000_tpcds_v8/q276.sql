WITH sales_cte AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        cs.cs_order_number,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450900 AND 2451000
      AND i.i_class_id = 12
),
inventory_cte AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_date_sk BETWEEN 2450900 AND 2451000
      AND i.i_class_id = 12
),
full_join AS (
    SELECT
        COALESCE(s.i_item_sk, inv.i_item_sk)          AS i_item_sk,
        COALESCE(s.i_item_id, inv.i_item_id)          AS i_item_id,
        s.cs_order_number,
        s.cs_ext_sales_price,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk
    FROM sales_cte s
    FULL OUTER JOIN inventory_cte inv
        ON s.i_item_sk = inv.i_item_sk
),
filtered_full AS (
    SELECT *
    FROM full_join
    WHERE cs_ext_sales_price > 1000 OR inv_quantity_on_hand > 0
),
another_set AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        CAST (NULL AS integer)         AS cs_order_number,
        CAST (NULL AS decimal(7,2))    AS cs_ext_sales_price,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_date_sk BETWEEN 2450900 AND 2451000
      AND i.i_class_id = 15
)
SELECT
    i_item_sk,
    i_item_id,
    cs_order_number,
    cs_ext_sales_price,
    inv_quantity_on_hand,
    inv_date_sk,
    ROW_NUMBER() OVER (ORDER BY i_item_sk) AS row_num
FROM (
    SELECT * FROM filtered_full
    EXCEPT
    SELECT * FROM another_set
) result
ORDER BY i_item_sk
LIMIT 100
