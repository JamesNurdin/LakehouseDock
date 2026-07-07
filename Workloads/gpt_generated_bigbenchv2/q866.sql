WITH sales_combined AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           i.i_category AS category
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           i.i_category AS category
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_per_item AS (
    SELECT sc.item_id,
           sc.category,
           SUM(sc.quantity) AS total_quantity,
           SUM(sc.quantity * sc.price) AS total_revenue
    FROM sales_combined sc
    GROUP BY sc.item_id, sc.category
),
item_sentiment AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(CAST(pr.pr_sentiment AS double)) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT spi.category,
       SUM(spi.total_quantity) AS category_quantity,
       SUM(spi.total_revenue) AS category_revenue,
       AVG(sent.avg_sentiment) AS avg_category_sentiment,
       SUM(sent.review_count) AS total_reviews
FROM sales_per_item spi
LEFT JOIN item_sentiment sent ON spi.item_id = sent.item_id
GROUP BY spi.category
ORDER BY category_revenue DESC
LIMIT 10
