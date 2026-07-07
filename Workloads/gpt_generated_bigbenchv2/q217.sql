WITH combined_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT item_id, SUM(quantity) AS total_qty
    FROM combined_sales
    GROUP BY item_id
),
reviews_agg AS (
    SELECT pr_item_id AS item_id, AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    SUM(s.total_qty) AS total_quantity_sold,
    SUM(i.i_price * s.total_qty) AS total_revenue,
    AVG(r.avg_sentiment) AS avg_review_sentiment
FROM sales_agg s
JOIN items i
    ON s.item_id = i.i_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
