WITH store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category
),
category_reviews AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(CAST(pr.pr_sentiment AS DOUBLE)) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category
)
SELECT
    s.s_store_name,
    c.i_category,
    s.total_quantity_sold,
    c.avg_sentiment,
    c.review_count
FROM store_category_sales s
JOIN category_reviews c
    ON s.i_category_id = c.i_category_id
    AND s.i_category = c.i_category
ORDER BY s.total_quantity_sold DESC
LIMIT 10
