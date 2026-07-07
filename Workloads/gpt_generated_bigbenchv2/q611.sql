WITH rev AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
ss AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_store_id) AS store_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
ws AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
price AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(i.i_price) AS avg_price,
           AVG(i.i_comp_price) AS avg_comp_price
    FROM items i
    GROUP BY i.i_category_id, i.i_category
)
SELECT rev.i_category_id,
       rev.i_category,
       price.avg_price,
       price.avg_comp_price,
       rev.avg_sentiment,
       rev.review_count,
       ss.total_store_quantity,
       ss.store_count,
       ws.total_web_quantity,
       ws.web_customer_count,
       (ss.total_store_quantity + ws.total_web_quantity) AS total_quantity_sold
FROM rev
JOIN ss ON rev.i_category_id = ss.i_category_id
JOIN ws ON rev.i_category_id = ws.i_category_id
JOIN price ON rev.i_category_id = price.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
