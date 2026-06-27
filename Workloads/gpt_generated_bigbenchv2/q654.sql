WITH avg_category_rating AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
sales_union AS (
    SELECT ss_item_id AS i_item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS i_item_id,
           ws_quantity AS quantity
    FROM web_sales
),
category_sales AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(su.quantity) AS total_quantity
    FROM sales_union su
    JOIN items i
        ON su.i_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.total_quantity,
    acr.avg_rating
FROM category_sales cs
LEFT JOIN avg_category_rating acr
    ON cs.i_category_id = acr.i_category_id
   AND cs.i_category_name = acr.i_category_name
ORDER BY cs.total_quantity DESC
LIMIT 10
