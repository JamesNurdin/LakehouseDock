WITH sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.s_store_name,
    sa.i_category,
    sa.total_quantity_sold,
    ra.avg_sentiment
FROM sales_agg sa
JOIN reviews_agg ra
    ON sa.i_category_id = ra.i_category_id
JOIN stores s
    ON sa.ss_store_id = s.s_store_id
ORDER BY ra.avg_sentiment DESC
LIMIT 10
