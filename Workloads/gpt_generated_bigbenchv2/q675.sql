WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
),
sales_agg AS (
    SELECT item_id,
           SUM(quantity) AS total_quantity
    FROM combined_sales
    GROUP BY item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(sa.total_quantity, 0) AS total_quantity,
       COALESCE(sa.total_quantity, 0) * i.i_price AS total_revenue,
       ra.avg_sentiment AS avg_review_sentiment,
       COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_revenue DESC
LIMIT 5
