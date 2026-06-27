WITH
    store_sales_agg AS (
        SELECT
            ss_item_id AS i_item_id,
            SUM(ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss_customer_id) AS store_customer_count
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id AS i_item_id,
            SUM(ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws_customer_id) AS web_customer_count
        FROM web_sales
        GROUP BY ws_item_id
    ),
    item_reviews AS (
        SELECT
            pr_item_id AS i_item_id,
            AVG(pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    top_store_per_item AS (
        SELECT
            ss_item_id AS i_item_id,
            ss_store_id AS s_store_id,
            SUM(ss_quantity) AS store_quantity_per_store,
            ROW_NUMBER() OVER (PARTITION BY ss_item_id ORDER BY SUM(ss_quantity) DESC) AS rn
        FROM store_sales
        GROUP BY ss_item_id, ss_store_id
    ),
    top_store AS (
        SELECT
            t.i_item_id,
            s.s_store_name,
            t.store_quantity_per_store AS top_store_quantity
        FROM top_store_per_item t
        JOIN stores s ON t.s_store_id = s.s_store_id
        WHERE t.rn = 1
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.web_quantity, 0) AS total_web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price AS total_revenue,
    COALESCE(ir.avg_rating, 0) AS avg_rating,
    COALESCE(ir.review_count, 0) AS review_count,
    COALESCE(sa.store_customer_count, 0) AS store_customer_count,
    COALESCE(wa.web_customer_count, 0) AS web_customer_count,
    ts.s_store_name AS top_store_name,
    ts.top_store_quantity,
    RANK() OVER (ORDER BY COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) DESC) AS quantity_rank
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN item_reviews ir ON i.i_item_id = ir.i_item_id
LEFT JOIN top_store ts ON i.i_item_id = ts.i_item_id
WHERE COALESCE(ir.review_count, 0) >= 5
  AND (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) > 0
ORDER BY quantity_rank
LIMIT 20
