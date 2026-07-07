WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_customers AS (
    SELECT i.i_category_id,
           i.i_category,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    UNION
    SELECT i.i_category_id,
           i.i_category,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),
customer_agg AS (
    SELECT i_category_id,
           i_category,
           COUNT(DISTINCT customer_id) AS distinct_customer_count
    FROM category_customers
    GROUP BY i_category_id, i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(ss.i_category_id, ws.i_category_id) AS i_category_id,
       COALESCE(ss.i_category, ws.i_category) AS i_category,
       ss.store_quantity,
       ws.web_quantity,
       ca.distinct_customer_count,
       ra.avg_sentiment
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
    AND ss.i_category = ws.i_category
LEFT JOIN customer_agg ca
    ON COALESCE(ss.i_category_id, ws.i_category_id) = ca.i_category_id
    AND COALESCE(ss.i_category, ws.i_category) = ca.i_category
LEFT JOIN review_agg ra
    ON COALESCE(ss.i_category_id, ws.i_category_id) = ra.i_category_id
    AND COALESCE(ss.i_category, ws.i_category) = ra.i_category
ORDER BY (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) DESC
