-- Top 10 items by combined store and web revenue, with sales volume, distinct customers, and review metrics
WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
sales_combined AS (
    SELECT
        COALESCE(ss.i_item_id, ws.i_item_id) AS i_item_id,
        COALESCE(ss.store_quantity, 0) AS store_quantity,
        COALESCE(ss.store_revenue, 0) AS store_revenue,
        COALESCE(ss.store_customers, 0) AS store_customers,
        COALESCE(ws.web_quantity, 0) AS web_quantity,
        COALESCE(ws.web_revenue, 0) AS web_revenue,
        COALESCE(ws.web_customers, 0) AS web_customers
    FROM store_sales_agg ss
    FULL OUTER JOIN web_sales_agg ws
        ON ss.i_item_id = ws.i_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    (sc.store_quantity + sc.web_quantity) AS total_quantity,
    (sc.store_revenue + sc.web_revenue) AS total_revenue,
    (sc.store_customers + sc.web_customers) AS distinct_customers_approx,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating
FROM sales_combined sc
JOIN items i
    ON sc.i_item_id = i.i_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
