WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
),
item_sales AS (
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    GROUP BY cs.item_id
),
item_reviews AS (
    SELECT pr.pr_item_id AS item_id,
           COUNT(*) AS review_count,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    isales.total_quantity,
    irev.review_count,
    irev.avg_rating,
    ROW_NUMBER() OVER (ORDER BY isales.total_quantity DESC) AS sales_rank
FROM item_sales isales
JOIN items i
    ON isales.item_id = i.i_item_id
LEFT JOIN item_reviews irev
    ON i.i_item_id = irev.item_id
ORDER BY isales.total_quantity DESC
LIMIT 100
