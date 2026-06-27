WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_qty,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_qty,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_counts AS (
    SELECT
        ss.ss_item_id,
        COUNT(DISTINCT ss.ss_store_id) AS distinct_store_count
    FROM store_sales ss
    GROUP BY ss.ss_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(sa.total_store_qty, 0) AS total_store_qty,
    COALESCE(wa.total_web_qty, 0) AS total_web_qty,
    COALESCE(sa.distinct_store_customers, 0) + COALESCE(wa.distinct_web_customers, 0) AS total_distinct_customers,
    COALESCE(sc.distinct_store_count, 0) AS distinct_store_count,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
LEFT JOIN store_counts sc ON sc.ss_item_id = i.i_item_id
WHERE i.i_price > 20
ORDER BY avg_rating DESC, (total_store_qty + total_web_qty) DESC
LIMIT 10
