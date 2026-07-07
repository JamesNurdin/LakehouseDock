WITH unified_sales AS (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity
        FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity
        FROM web_sales
    ),
    sales_agg AS (
        SELECT
            i.i_category_id,
            i.i_category,
            SUM(us.quantity) AS total_quantity,
            AVG(i.i_price) AS avg_price
        FROM items i
        LEFT JOIN unified_sales us ON us.item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category
    ),
    review_agg AS (
        SELECT
            i.i_category_id,
            i.i_category,
            AVG(pr.pr_sentiment) AS avg_sentiment,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category
    )
SELECT
    s.i_category_id,
    s.i_category,
    s.total_quantity,
    s.avg_price,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
JOIN review_agg r ON s.i_category_id = r.i_category_id
ORDER BY s.total_quantity DESC
LIMIT 10
