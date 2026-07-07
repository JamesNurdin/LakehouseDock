WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY pr.pr_item_id
),
distinct_customers_agg AS (
    SELECT
        i.i_category_id,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM (
        SELECT ss.ss_customer_id AS c_customer_id, ss.ss_item_id AS i_item_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_customer_id AS c_customer_id, ws.ws_item_id AS i_item_id
        FROM web_sales ws
    ) sc
    JOIN customers c ON sc.c_customer_id = c.c_customer_id
    JOIN items i ON sc.i_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    i.i_category_id,
    i.i_category,
    COALESCE(SUM(ss.store_qty), 0) AS total_store_quantity,
    COALESCE(SUM(ss.store_revenue), 0.0) AS total_store_revenue,
    COALESCE(SUM(ws.web_qty), 0) AS total_web_quantity,
    COALESCE(SUM(ws.web_revenue), 0.0) AS total_web_revenue,
    COALESCE(SUM(pr.avg_sentiment * pr.review_count), 0) / NULLIF(SUM(pr.review_count), 0) AS avg_sentiment,
    COALESCE(SUM(pr.review_count), 0) AS total_review_count,
    COALESCE(MAX(dc.distinct_customers), 0) AS distinct_customers
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
LEFT JOIN reviews_agg pr ON i.i_item_id = pr.i_item_id
LEFT JOIN distinct_customers_agg dc ON i.i_category_id = dc.i_category_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_store_revenue DESC
LIMIT 10
