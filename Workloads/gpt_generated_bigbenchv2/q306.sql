WITH
    store_sales_agg AS (
        SELECT
            ss_item_id,
            SUM(ss_quantity) AS store_qty,
            COUNT(DISTINCT ss_customer_id) AS store_customer_cnt
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS web_qty,
            COUNT(DISTINCT ws_customer_id) AS web_customer_cnt
        FROM web_sales
        GROUP BY ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr_item_id,
            SUM(pr_sentiment) AS sum_sentiment,
            COUNT(*) AS review_cnt
        FROM product_reviews
        GROUP BY pr_item_id
    )
SELECT
    i.i_category_id,
    i.i_category,
    SUM(COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0)) AS total_quantity_sold,
    SUM(COALESCE(sa.store_customer_cnt, 0) + COALESCE(wa.web_customer_cnt, 0)) AS total_distinct_customers,
    SUM(COALESCE(r.sum_sentiment, 0)) / NULLIF(SUM(COALESCE(r.review_cnt, 0)), 0) AS avg_sentiment_per_category,
    SUM(COALESCE(r.review_cnt, 0)) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
