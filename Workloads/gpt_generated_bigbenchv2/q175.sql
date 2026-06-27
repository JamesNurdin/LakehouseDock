WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        ss_store_id,
        SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id, ss_store_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
rating_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
customer_counts AS (
    SELECT
        item_id,
        SUM(customer_cnt) AS total_customer_count
    FROM (
        SELECT
            ss_item_id AS item_id,
            COUNT(DISTINCT ss_customer_id) AS customer_cnt
        FROM store_sales
        GROUP BY ss_item_id
        UNION ALL
        SELECT
            ws_item_id AS item_id,
            COUNT(DISTINCT ws_customer_id) AS customer_cnt
        FROM web_sales
        GROUP BY ws_item_id
    ) sub
    GROUP BY item_id
)
SELECT
    i.i_category_name,
    s.s_store_name,
    i.i_name,
    i.i_price,
    COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(cc.total_customer_count, 0) AS total_customer_count
FROM items i
LEFT JOIN store_sales_agg ss
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN stores s
    ON ss.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws
    ON ws.ws_item_id = i.i_item_id
LEFT JOIN rating_agg r
    ON r.pr_item_id = i.i_item_id
LEFT JOIN customer_counts cc
    ON cc.item_id = i.i_item_id
WHERE i.i_price > 20.00
ORDER BY (COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0)) DESC,
         i.i_category_name
LIMIT 100
