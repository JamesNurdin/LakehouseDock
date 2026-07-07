WITH item_price_agg AS (
    SELECT i.i_category,
           AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category
),
store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
distinct_customers_agg AS (
    SELECT c.i_category,
           COUNT(DISTINCT c.cust_id) AS total_distinct_customers
    FROM (
        SELECT i.i_category AS i_category, ss.ss_customer_id AS cust_id
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT i.i_category AS i_category, ws.ws_customer_id AS cust_id
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ) c
    GROUP BY c.i_category
)
SELECT ip.i_category,
       COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(dca.total_distinct_customers, 0) AS total_distinct_customers,
       COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count,
       COALESCE(ip.avg_price, 0) AS avg_price
FROM item_price_agg ip
LEFT JOIN store_sales_agg ssa ON ip.i_category = ssa.i_category
LEFT JOIN web_sales_agg wsa ON ip.i_category = wsa.i_category
LEFT JOIN distinct_customers_agg dca ON ip.i_category = dca.i_category
LEFT JOIN review_agg ra ON ip.i_category = ra.i_category
ORDER BY ip.i_category
