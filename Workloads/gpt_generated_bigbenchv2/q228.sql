WITH store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
customers_agg AS (
    SELECT category,
           COUNT(DISTINCT cust_id) AS distinct_customers
    FROM (
        SELECT ss.ss_customer_id AS cust_id, i.i_category AS category
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION
        SELECT ws.ws_customer_id AS cust_id, i.i_category AS category
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ) AS combined
    GROUP BY category
)
SELECT COALESCE(ss.i_category, ws.i_category, r.i_category, c.category) AS category,
       ss.total_store_quantity,
       ws.total_web_quantity,
       r.avg_sentiment,
       r.review_count,
       c.distinct_customers
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.i_category = ws.i_category
FULL OUTER JOIN reviews_agg r ON COALESCE(ss.i_category, ws.i_category) = r.i_category
FULL OUTER JOIN customers_agg c ON COALESCE(ss.i_category, ws.i_category, r.i_category) = c.category
ORDER BY category
