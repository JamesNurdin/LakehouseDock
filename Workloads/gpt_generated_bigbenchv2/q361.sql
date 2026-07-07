WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS ss_qty,
           COUNT(DISTINCT ss_customer_id) AS ss_cust_cnt
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS ws_qty,
           COUNT(DISTINCT ws_customer_id) AS ws_cust_cnt
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(COALESCE(ss.ss_qty, 0) + COALESCE(ws.ws_qty, 0)) AS total_quantity_sold,
       SUM(COALESCE(r.review_cnt, 0)) AS total_reviews,
       AVG(r.avg_sentiment) AS avg_sentiment_per_category
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN review_agg r ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
