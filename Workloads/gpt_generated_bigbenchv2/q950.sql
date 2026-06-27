WITH
    store_agg AS (
        SELECT
            ss_item_id AS i_item_id,
            SUM(ss_quantity) AS store_quantity,
            COUNT(*) AS store_transactions,
            COUNT(DISTINCT ss_customer_id) AS store_customers
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_agg AS (
        SELECT
            ws_item_id AS i_item_id,
            SUM(ws_quantity) AS web_quantity,
            COUNT(*) AS web_transactions,
            COUNT(DISTINCT ws_customer_id) AS web_customers
        FROM web_sales
        GROUP BY ws_item_id
    ),
    review_agg AS (
        SELECT
            pr_item_id AS i_item_id,
            AVG(pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    item_metrics AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
            (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price AS total_revenue,
            COALESCE(sa.store_quantity, 0) AS store_quantity,
            COALESCE(wa.web_quantity, 0) AS web_quantity,
            COALESCE(sa.store_transactions, 0) AS store_transactions,
            COALESCE(wa.web_transactions, 0) AS web_transactions,
            COALESCE(ra.avg_rating, 0) AS avg_rating,
            COALESCE(ra.review_count, 0) AS review_count,
            ROW_NUMBER() OVER (
                PARTITION BY i.i_category_id
                ORDER BY (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price DESC
            ) AS category_rank
        FROM items i
        LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
        LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
        LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
        WHERE COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) > 0
    )
SELECT
    i_item_id,
    i_name,
    i_category_id,
    i_category_name,
    total_quantity,
    total_revenue,
    store_quantity,
    web_quantity,
    store_transactions,
    web_transactions,
    avg_rating,
    review_count,
    category_rank
FROM item_metrics
WHERE category_rank <= 3
ORDER BY i_category_id, category_rank
