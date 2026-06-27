WITH
    store_agg AS (
        SELECT
            ss_item_id AS i_item_id,
            SUM(ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss_customer_id) AS store_customer_count
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_agg AS (
        SELECT
            ws_item_id AS i_item_id,
            SUM(ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws_customer_id) AS web_customer_count
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
    item_sales AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            i.i_item_id,
            i.i_name,
            i.i_price,
            COALESCE(sa.store_quantity, 0) AS store_quantity,
            COALESCE(wa.web_quantity, 0) AS web_quantity,
            COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
            COALESCE(sa.store_customer_count, 0) + COALESCE(wa.web_customer_count, 0) AS total_customers,
            COALESCE(ra.avg_rating, 0) AS avg_rating,
            COALESCE(ra.review_count, 0) AS review_count
        FROM items i
        LEFT JOIN store_agg sa ON sa.i_item_id = i.i_item_id
        LEFT JOIN web_agg wa ON wa.i_item_id = i.i_item_id
        LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
        WHERE i.i_price > 20
    )
SELECT
    i_category_id,
    i_category_name,
    i_item_id,
    i_name,
    i_price,
    store_quantity,
    web_quantity,
    total_quantity,
    total_customers,
    avg_rating,
    review_count,
    ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY total_quantity DESC) AS category_rank
FROM item_sales
WHERE total_quantity > 0
ORDER BY total_quantity DESC
LIMIT 50
