WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_store_id AS store_id,
           ss.ss_quantity AS quantity,
           i.i_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           CAST(NULL AS BIGINT) AS store_id,
           ws.ws_quantity AS quantity,
           i.i_price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT item_id,
           store_id,
           SUM(quantity) AS total_quantity,
           SUM(quantity * i_price) AS total_revenue
    FROM combined_sales
    GROUP BY item_id, store_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    i.i_name AS item_name,
    COALESCE(s.s_store_name, 'Online') AS store_name,
    sa.total_quantity,
    sa.total_revenue,
    ra.avg_sentiment,
    ra.review_count
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN stores s ON sa.store_id = s.s_store_id
LEFT JOIN review_agg ra ON sa.item_id = ra.item_id
ORDER BY i.i_category, store_name, total_revenue DESC
