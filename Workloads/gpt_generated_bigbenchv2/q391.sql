WITH store_sales_join AS (
    SELECT ss.ss_customer_id AS customer_id,
           i.i_category_id,
           i.i_category,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_join AS (
    SELECT ws.ws_customer_id AS customer_id,
           i.i_category_id,
           i.i_category,
           ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_union AS (
    SELECT customer_id,
           i_category_id,
           i_category,
           quantity,
           'store' AS source
    FROM store_sales_join
    UNION ALL
    SELECT customer_id,
           i_category_id,
           i_category,
           quantity,
           'web' AS source
    FROM web_sales_join
),
sales_agg AS (
    SELECT i_category_id,
           i_category,
           SUM(CASE WHEN source = 'store' THEN quantity ELSE 0 END) AS total_store_qty,
           SUM(CASE WHEN source = 'web' THEN quantity ELSE 0 END) AS total_web_qty,
           COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM sales_union
    GROUP BY i_category_id, i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT s.i_category_id AS category_id,
       s.i_category AS category_name,
       s.total_store_qty,
       s.total_web_qty,
       s.distinct_customer_count,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_cnt, 0) AS review_cnt
FROM sales_agg s
LEFT JOIN review_agg r
  ON s.i_category_id = r.i_category_id
ORDER BY s.total_store_qty DESC, s.total_web_qty DESC
