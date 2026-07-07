WITH sales AS (
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           i.i_name,
           i.i_price,
           ss.ss_quantity AS quantity_sold
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_item_id,
           i.i_category_id,
           i.i_category,
           i.i_name,
           i.i_price,
           ws.ws_quantity AS quantity_sold
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
item_sales AS (
    SELECT i_item_id,
           i_category_id,
           i_category,
           i_name,
           i_price,
           SUM(quantity_sold) AS total_quantity,
           SUM(i_price * quantity_sold) AS total_revenue
    FROM sales
    GROUP BY i_item_id, i_category_id, i_category, i_name, i_price
),
item_reviews AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT isales.i_category AS category,
       isales.i_category_id,
       SUM(isales.total_quantity) AS category_total_quantity,
       SUM(isales.total_revenue) AS category_total_revenue,
       AVG(irev.avg_sentiment) AS category_avg_sentiment,
       SUM(irev.review_count) AS category_review_count
FROM item_sales isales
LEFT JOIN item_reviews irev ON isales.i_item_id = irev.i_item_id
GROUP BY isales.i_category, isales.i_category_id
ORDER BY category_total_revenue DESC
LIMIT 10
