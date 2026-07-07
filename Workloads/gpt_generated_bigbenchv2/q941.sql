WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_qty,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers_store
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers_web
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ss_agg.i_category_id,
    ss_agg.i_category,
    ss_agg.store_qty,
    COALESCE(ws_agg.web_qty, 0) AS web_qty,
    COALESCE(rev_agg.avg_sentiment, NULL) AS avg_sentiment,
    ss_agg.distinct_customers_store + COALESCE(ws_agg.distinct_customers_web, 0) AS total_distinct_customers,
    COALESCE(rev_agg.review_count, 0) AS review_count
FROM stores s
JOIN store_sales_agg ss_agg
    ON s.s_store_id = ss_agg.ss_store_id
LEFT JOIN web_sales_agg ws_agg
    ON ss_agg.i_category_id = ws_agg.i_category_id
    AND ss_agg.i_category = ws_agg.i_category
LEFT JOIN reviews_agg rev_agg
    ON ss_agg.i_category_id = rev_agg.i_category_id
    AND ss_agg.i_category = rev_agg.i_category
ORDER BY s.s_store_name, ss_agg.i_category_id
