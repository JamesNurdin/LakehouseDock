WITH store_sales_agg AS (
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
review_agg AS (
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
    ss_agg.i_category,
    ss_agg.total_quantity_sold,
    rev_agg.avg_sentiment
FROM store_sales_agg ss_agg
JOIN stores s
    ON ss_agg.ss_store_id = s.s_store_id
JOIN review_agg rev_agg
    ON ss_agg.i_category_id = rev_agg.i_category_id
ORDER BY ss_agg.total_quantity_sold DESC
LIMIT 10
