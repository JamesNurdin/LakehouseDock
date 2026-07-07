WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category,
    i.i_category_id,
    ss_agg.total_quantity_sold,
    COALESCE(r_agg.review_count, 0) AS review_count,
    r_agg.avg_sentiment
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
JOIN items i ON ss_agg.ss_item_id = i.i_item_id
LEFT JOIN reviews_agg r_agg ON i.i_item_id = r_agg.pr_item_id
ORDER BY s.s_store_name, i.i_category_id
