WITH store_agg AS (
    SELECT ss_item_id, SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id, SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           COALESCE(sa.store_quantity, 0) AS store_quantity,
           COALESCE(wa.web_quantity, 0) AS web_quantity,
           COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
    LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
),
sales_by_category AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(i.store_quantity) AS store_quantity,
           SUM(i.web_quantity) AS web_quantity,
           SUM(i.total_quantity) AS total_quantity
    FROM item_sales i
    GROUP BY i.i_category_id, i.i_category
),
review_by_category AS (
    SELECT i.i_category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT sbc.i_category,
       sbc.total_quantity,
       sbc.store_quantity,
       sbc.web_quantity,
       rbc.avg_sentiment
FROM sales_by_category sbc
LEFT JOIN review_by_category rbc ON rbc.i_category_id = sbc.i_category_id
ORDER BY sbc.total_quantity DESC
LIMIT 10
