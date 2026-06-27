WITH combined_sales AS (
    SELECT
        ss_item_id AS item_id,
        ss_store_id AS store_id,
        ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT
        ws_item_id AS item_id,
        NULL AS store_id,
        ws_quantity AS quantity
    FROM web_sales
),

sales_agg AS (
    SELECT
        item_id,
        store_id,
        SUM(quantity) AS total_quantity
    FROM combined_sales
    GROUP BY
        item_id,
        store_id
),

product_reviews_agg AS (
    SELECT
        pr_item_id AS item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY
        pr_item_id
)
SELECT
    i.i_category_name,
    COALESCE(s.s_store_name, 'Online') AS store_name,
    i.i_name AS item_name,
    i.i_price,
    COALESCE(sa.total_quantity, 0) AS total_quantity,
    COALESCE(sa.total_quantity, 0) * i.i_price AS total_revenue,
    COALESCE(pr.review_count, 0) AS review_count,
    pr.avg_rating
FROM sales_agg sa
LEFT JOIN items i
    ON sa.item_id = i.i_item_id
LEFT JOIN stores s
    ON sa.store_id = s.s_store_id
LEFT JOIN product_reviews_agg pr
    ON i.i_item_id = pr.item_id
ORDER BY total_revenue DESC
LIMIT 100
