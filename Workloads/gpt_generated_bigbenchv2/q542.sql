WITH combined_sales AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           i.i_price,
           SUM(ss.ss_quantity) AS quantity_sold
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category, i.i_category_id, i.i_price
    UNION ALL
    SELECT i.i_item_id,
           i.i_category,
           i.i_category_id,
           i.i_price,
           SUM(ws.ws_quantity) AS quantity_sold
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category, i.i_category_id, i.i_price
),

sales_agg AS (
    SELECT i_item_id,
           i_category,
           i_category_id,
           i_price,
           SUM(quantity_sold) AS total_quantity_sold,
           SUM(i_price * quantity_sold) AS total_sales_amount
    FROM combined_sales
    GROUP BY i_item_id, i_category, i_category_id, i_price
),

reviews_agg AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT s.i_category,
       SUM(s.total_quantity_sold) AS category_quantity_sold,
       SUM(s.total_sales_amount) AS category_sales_amount,
       AVG(r.avg_sentiment) AS avg_category_sentiment,
       SUM(r.review_count) AS total_reviews
FROM sales_agg s
LEFT JOIN reviews_agg r ON s.i_item_id = r.pr_item_id
GROUP BY s.i_category
ORDER BY category_sales_amount DESC
LIMIT 10
