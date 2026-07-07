WITH store_agg AS (
    SELECT
        ss_item_id AS i_item_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id AS i_item_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
sales_agg AS (
    SELECT
        COALESCE(sa.i_item_id, wa.i_item_id) AS i_item_id,
        COALESCE(sa.store_quantity, 0) AS store_quantity,
        COALESCE(wa.web_quantity, 0) AS web_quantity,
        COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
        COALESCE(sa.distinct_store_customers, 0) + COALESCE(wa.distinct_web_customers, 0) AS distinct_customers
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa ON sa.i_item_id = wa.i_item_id
),
review_agg AS (
    SELECT
        pr_item_id AS i_item_id,
        AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    sa.store_quantity,
    sa.web_quantity,
    sa.total_quantity,
    ra.avg_sentiment,
    sa.distinct_customers
FROM items i
LEFT JOIN sales_agg sa ON sa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
WHERE sa.total_quantity > 0
ORDER BY sa.total_quantity DESC
LIMIT 10
