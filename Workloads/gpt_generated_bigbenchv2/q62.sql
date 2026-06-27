WITH
    store_sales_agg AS (
        SELECT
            ss_item_id,
            SUM(ss_quantity) AS store_qty,
            COUNT(DISTINCT ss_customer_id) AS store_customers
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS web_qty,
            COUNT(DISTINCT ws_customer_id) AS web_customers
        FROM web_sales
        GROUP BY ws_item_id
    ),
    item_reviews_agg AS (
        SELECT
            pr_item_id,
            COUNT(*) AS review_count,
            AVG(pr_rating) AS avg_rating
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
            COALESCE(ssa.store_qty, 0) AS store_qty,
            COALESCE(wsa.web_qty, 0) AS web_qty,
            COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0) AS total_qty,
            COALESCE(ssa.store_customers, 0) AS store_customers,
            COALESCE(wsa.web_customers, 0) AS web_customers,
            COALESCE(ssa.store_customers, 0) + COALESCE(wsa.web_customers, 0) AS total_customers,
            COALESCE(ira.review_count, 0) AS review_count,
            ira.avg_rating,
            ROW_NUMBER() OVER (
                PARTITION BY i.i_category_id
                ORDER BY COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0) DESC
            ) AS category_item_rank
        FROM items i
        LEFT JOIN store_sales_agg ssa ON ssa.ss_item_id = i.i_item_id
        LEFT JOIN web_sales_agg wsa ON wsa.ws_item_id = i.i_item_id
        LEFT JOIN item_reviews_agg ira ON ira.pr_item_id = i.i_item_id
    )
SELECT
    i_category_name,
    i_category_id,
    i_item_id,
    i_name,
    i_price,
    store_qty,
    web_qty,
    total_qty,
    total_customers,
    review_count,
    avg_rating
FROM item_sales
WHERE category_item_rank <= 5
ORDER BY i_category_id, total_qty DESC
