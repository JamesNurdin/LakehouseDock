WITH store_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_qty,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_qty,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT i.i_item_id,
           SUM(pr.pr_rating) AS rating_sum,
           COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_category_name,
       SUM(COALESCE(ss.store_qty, 0)) AS total_store_quantity,
       SUM(COALESCE(ws.web_qty, 0)) AS total_web_quantity,
       SUM(COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) AS total_quantity,
       SUM(COALESCE(ss.store_customers, 0)) AS total_store_customers,
       SUM(COALESCE(ws.web_customers, 0)) AS total_web_customers,
       SUM(COALESCE(ss.store_customers, 0) + COALESCE(ws.web_customers, 0)) AS total_customers,
       AVG(i.i_price) AS avg_item_price,
       SUM(COALESCE(r.rating_sum, 0)) AS total_rating_sum,
       SUM(COALESCE(r.review_cnt, 0)) AS total_review_count,
       CASE WHEN SUM(COALESCE(r.review_cnt, 0)) > 0
            THEN SUM(COALESCE(r.rating_sum, 0)) / SUM(COALESCE(r.review_cnt, 0))
            ELSE NULL
       END AS avg_rating,
       COUNT(DISTINCT i.i_item_id) AS distinct_items
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_name
ORDER BY total_quantity DESC
