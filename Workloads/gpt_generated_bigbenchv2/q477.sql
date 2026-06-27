WITH
    store_sales_agg AS (
        SELECT
            i.i_item_id,
            i.i_category_id,
            i.i_category_name,
            i.i_price,
            SUM(ss.ss_quantity) AS store_quantity
        FROM items i
        JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_item_id, i.i_category_id, i.i_category_name, i.i_price
    ),
    web_sales_agg AS (
        SELECT
            i.i_item_id,
            SUM(ws.ws_quantity) AS web_quantity
        FROM items i
        JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    review_agg AS (
        SELECT
            i.i_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM items i
        JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    category_customer AS (
        SELECT
            category_id,
            COUNT(DISTINCT customer_id) AS distinct_customers
        FROM (
            SELECT i.i_category_id AS category_id, ss.ss_customer_id AS customer_id
            FROM store_sales ss
            JOIN items i ON ss.ss_item_id = i.i_item_id
            UNION
            SELECT i.i_category_id AS category_id, ws.ws_customer_id AS customer_id
            FROM web_sales ws
            JOIN items i ON ws.ws_item_id = i.i_item_id
        ) t
        GROUP BY category_id
    )
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(ssa.store_quantity, 0) * i.i_price) + SUM(COALESCE(wsa.web_quantity, 0) * i.i_price) AS total_sales_amount,
    AVG(COALESCE(ra.avg_rating, 0)) AS avg_item_rating,
    SUM(COALESCE(ra.review_count, 0)) AS total_reviews,
    MAX(cc.distinct_customers) AS distinct_customers
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.i_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
LEFT JOIN category_customer cc ON cc.category_id = i.i_category_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 5
