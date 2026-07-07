WITH store_sales_agg AS (
    SELECT
        ss_item_id AS item_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_customer_id) AS store_customer_count
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id AS item_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws_customer_id) AS web_customer_count
    FROM web_sales
    GROUP BY ws_item_id
),
sales_agg AS (
    SELECT
        COALESCE(s.item_id, w.item_id) AS item_id,
        COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
        COALESCE(s.store_customer_count, 0) + COALESCE(w.web_customer_count, 0) AS total_customer_count
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.item_id = w.item_id
),
review_agg AS (
    SELECT
        pr_item_id AS item_id,
        AVG(pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(sa.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sa.total_customer_count, 0) AS total_customers,
    COALESCE(ra.avg_sentiment, 0) AS avg_review_sentiment,
    COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_quantity_sold DESC
LIMIT 10
