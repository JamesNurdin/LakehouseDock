WITH sales AS (
    SELECT ss_store_id AS store_id,
           ss_item_id,
           ss_quantity
    FROM store_sales
    UNION ALL
    SELECT NULL AS store_id,
           ws_item_id AS ss_item_id,
           ws_quantity AS ss_quantity
    FROM web_sales
),
sales_items AS (
    SELECT s.store_id,
           st.s_store_name,
           i.i_category_id,
           i.i_category,
           s.ss_quantity,
           i.i_item_id
    FROM sales s
    JOIN items i ON s.ss_item_id = i.i_item_id
    LEFT JOIN stores st ON s.store_id = st.s_store_id
),
reviews AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(si.s_store_name, 'Online') AS store_name,
    si.i_category,
    SUM(si.ss_quantity) AS total_quantity_sold,
    r.avg_sentiment
FROM sales_items si
LEFT JOIN reviews r ON si.i_category_id = r.i_category_id
GROUP BY
    COALESCE(si.s_store_name, 'Online'),
    si.i_category,
    r.avg_sentiment
ORDER BY total_quantity_sold DESC
LIMIT 10
