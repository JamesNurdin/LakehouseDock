WITH sales_union AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        i.i_price,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        i.i_price,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        i_item_id,
        i_category_id,
        i_category,
        i_price,
        SUM(quantity) AS total_quantity
    FROM sales_union
    GROUP BY i_item_id, i_category_id, i_category, i_price
),
review_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    sa.i_category_id,
    sa.i_category,
    SUM(sa.total_quantity * sa.i_price) AS total_revenue,
    SUM(sa.total_quantity) AS total_quantity_sold,
    AVG(COALESCE(ra.avg_sentiment, 0)) AS avg_sentiment,
    SUM(COALESCE(ra.review_count, 0)) AS total_reviews
FROM sales_agg sa
LEFT JOIN review_agg ra ON sa.i_item_id = ra.i_item_id
GROUP BY sa.i_category_id, sa.i_category
ORDER BY total_revenue DESC
LIMIT 10
