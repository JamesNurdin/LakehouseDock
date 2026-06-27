WITH sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS num_items,
    SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(s.total_revenue, 0)) AS total_revenue,
    AVG(r.avg_rating) AS avg_item_rating,
    SUM(COALESCE(r.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN sales_agg s
    ON i.i_item_id = s.i_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
