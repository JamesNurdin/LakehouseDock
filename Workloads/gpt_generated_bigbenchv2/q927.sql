WITH
    store_sales_agg AS (
        SELECT
            ss.ss_item_id AS item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
        FROM store_sales ss
        GROUP BY ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id AS item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
        FROM web_sales ws
        GROUP BY ws.ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr.pr_item_id AS item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_cnt
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    distinct_customers AS (
        SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id
        FROM web_sales ws
    ),
    customer_counts AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_customer_cnt
        FROM distinct_customers
        GROUP BY item_id
    )
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(ssa.store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wsa.web_quantity, 0)) AS total_web_quantity,
    AVG(r.avg_rating) AS avg_item_rating,
    SUM(r.review_cnt) AS total_reviews,
    SUM(COALESCE(cc.distinct_customer_cnt, 0)) AS total_distinct_customers
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
LEFT JOIN customer_counts cc ON cc.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 10
