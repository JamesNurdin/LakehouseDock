WITH sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity
    FROM (
        SELECT ss_item_id AS item_id, ss_quantity AS quantity
        FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_quantity AS quantity
        FROM web_sales
    ) s
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category AS category,
       SUM(COALESCE(sa.total_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_item_price,
       AVG(r.avg_sentiment) AS avg_review_sentiment
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
