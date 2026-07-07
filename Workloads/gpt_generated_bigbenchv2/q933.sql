WITH store_sales_agg AS (
    SELECT ss.ss_item_id AS ss_item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS ws_item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT pr.pr_item_id AS pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
distinct_customers_agg AS (
    SELECT combined.item_id,
           COUNT(DISTINCT combined.customer_id) AS distinct_customer_count
    FROM (
        SELECT ss.ss_item_id AS item_id,
               ss.ss_customer_id AS customer_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_id AS item_id,
               ws.ws_customer_id AS customer_id
        FROM web_sales ws
    ) AS combined
    GROUP BY combined.item_id
)
SELECT i.i_category,
       i.i_category_id,
       i.i_name,
       i.i_price,
       COALESCE(ss.store_quantity, 0) AS store_quantity,
       COALESCE(ws.web_quantity, 0) AS web_quantity,
       (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity,
       (i.i_price * (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0))) AS total_revenue,
       r.avg_sentiment,
       r.review_count,
       dc.distinct_customer_count
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.pr_item_id
LEFT JOIN distinct_customers_agg dc ON i.i_item_id = dc.item_id
ORDER BY total_revenue DESC
LIMIT 100
