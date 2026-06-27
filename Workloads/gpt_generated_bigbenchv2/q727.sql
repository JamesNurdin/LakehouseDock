WITH item_ratings AS (
    SELECT
        pr_item_id,
        AVG(CAST(pr_rating AS DOUBLE)) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
store_category_sales AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
        AVG(ir.avg_rating) AS avg_item_rating,
        SUM(ir.review_count) AS total_reviews
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir
        ON i.i_item_id = ir.pr_item_id
    GROUP BY
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
)
SELECT
    s_store_name,
    i_category_name,
    total_quantity,
    total_revenue,
    distinct_items_sold,
    avg_item_rating,
    total_reviews
FROM store_category_sales
ORDER BY total_revenue DESC
LIMIT 10
