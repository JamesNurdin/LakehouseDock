WITH store_category_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
store_category_sentiment AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_category AS category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
)
SELECT
    s.s_store_id,
    s.s_store_name,
    scs.category,
    scs.total_quantity,
    scsnt.avg_sentiment,
    scsnt.review_count
FROM store_category_sales scs
JOIN store_category_sentiment scsnt
    ON scs.store_id = scsnt.store_id
    AND scs.category = scsnt.category
JOIN stores s
    ON scs.store_id = s.s_store_id
ORDER BY scs.total_quantity DESC
LIMIT 50
