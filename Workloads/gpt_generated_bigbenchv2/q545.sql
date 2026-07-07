WITH review_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_category_id,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(ra.avg_sentiment) AS avg_item_sentiment,
    SUM(ra.review_count) AS total_review_count
FROM store_sales ss
JOIN customers c
    ON ss.ss_customer_id = c.c_customer_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
LEFT JOIN review_agg ra
    ON ra.pr_item_id = i.i_item_id
GROUP BY
    s.s_store_id,
    s.s_store_name,
    i.i_category_id,
    i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
