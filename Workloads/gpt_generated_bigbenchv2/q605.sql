WITH store_sales_agg AS (
    SELECT i.i_category,
           i.i_item_id,
           SUM(ss.ss_quantity) AS store_qty,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_category,
           i.i_item_id,
           SUM(ws.ws_quantity) AS web_qty,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id
),
reviews_agg AS (
    SELECT i.i_category,
           i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_item_id
),
customer_union AS (
    SELECT i.i_category,
           i.i_item_id,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION
    SELECT i.i_category,
           i.i_item_id,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
customer_agg AS (
    SELECT i_category,
           i_item_id,
           COUNT(DISTINCT customer_id) AS distinct_customer_cnt
    FROM customer_union
    GROUP BY i_category, i_item_id
)
SELECT i.i_category,
       SUM(COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0)) AS total_quantity_sold,
       AVG(COALESCE(r.avg_sentiment, 0)) AS avg_review_sentiment,
       SUM(COALESCE(ca.distinct_customer_cnt, 0)) AS total_distinct_customers
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
LEFT JOIN customer_agg ca ON i.i_item_id = ca.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
