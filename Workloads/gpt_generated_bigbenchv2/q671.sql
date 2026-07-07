WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_qty,
           COUNT(DISTINCT ss_customer_id) AS store_customer_cnt
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_qty,
           COUNT(DISTINCT ws_customer_id) AS web_customer_cnt
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(pr_review_id) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(sa.store_qty, 0)) AS total_store_quantity,
       SUM(COALESCE(wa.web_qty, 0)) AS total_web_quantity,
       SUM(COALESCE(sa.store_customer_cnt, 0)) AS total_store_customers,
       SUM(COALESCE(wa.web_customer_cnt, 0)) AS total_web_customers,
       CASE WHEN SUM(COALESCE(ra.review_cnt, 0)) > 0
            THEN SUM(COALESCE(ra.avg_sentiment * ra.review_cnt, 0)) / SUM(COALESCE(ra.review_cnt, 0))
            ELSE NULL
       END AS avg_review_sentiment,
       SUM(COALESCE(ra.review_cnt, 0)) AS total_review_count
FROM items i
LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY i.i_category_id
