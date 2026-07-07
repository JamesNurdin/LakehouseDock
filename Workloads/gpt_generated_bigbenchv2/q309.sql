WITH store_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
customer_agg AS (
    SELECT combined.category_id,
           combined.category,
           COUNT(DISTINCT combined.customer_id) AS distinct_customer_count
    FROM (
        SELECT ss.ss_customer_id AS customer_id,
               i.i_category_id AS category_id,
               i.i_category AS category
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT ws.ws_customer_id AS customer_id,
               i.i_category_id AS category_id,
               i.i_category AS category
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ) combined
    GROUP BY combined.category_id, combined.category
)
SELECT COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id, ca.category_id) AS category_id,
       COALESCE(sa.i_category, wa.i_category, ra.i_category, ca.category) AS category,
       COALESCE(sa.store_quantity, 0) AS store_quantity,
       COALESCE(sa.store_revenue, 0) AS store_revenue,
       COALESCE(wa.web_quantity, 0) AS web_quantity,
       COALESCE(wa.web_revenue, 0) AS web_revenue,
       ra.avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count,
       COALESCE(ca.distinct_customer_count, 0) AS distinct_customer_count
FROM store_agg sa
FULL OUTER JOIN web_agg wa ON sa.i_category_id = wa.i_category_id
FULL OUTER JOIN review_agg ra ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
FULL OUTER JOIN customer_agg ca ON COALESCE(sa.i_category_id, wa.i_category_id) = ca.category_id
ORDER BY category_id
