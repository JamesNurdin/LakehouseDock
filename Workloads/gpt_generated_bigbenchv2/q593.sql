WITH sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_item_id
    UNION ALL
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
sales_total AS (
    SELECT item_id,
           SUM(total_quantity) AS total_quantity
    FROM sales_agg
    GROUP BY item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(s.total_quantity, 0) AS total_quantity_sold,
       r.avg_sentiment AS average_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN sales_total s ON i.i_item_id = s.item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
