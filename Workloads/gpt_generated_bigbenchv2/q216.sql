WITH
    store_agg AS (
        SELECT ss_item_id AS item_id,
               SUM(ss_quantity) AS total_store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_agg AS (
        SELECT ws_item_id AS item_id,
               SUM(ws_quantity) AS total_web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ),
    cust_agg AS (
        SELECT item_id,
               COUNT(DISTINCT customer_id) AS distinct_customers
        FROM (
            SELECT ss_item_id AS item_id, ss_customer_id AS customer_id
            FROM store_sales
            UNION ALL
            SELECT ws_item_id AS item_id, ws_customer_id AS customer_id
            FROM web_sales
        ) AS combined
        GROUP BY item_id
    ),
    review_agg AS (
        SELECT pr_item_id AS item_id,
               AVG(pr_rating) AS avg_rating,
               COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity,
    COALESCE(c.distinct_customers, 0) AS distinct_customers,
    r.avg_rating,
    r.review_count
FROM items i
LEFT JOIN store_agg s ON i.i_item_id = s.item_id
LEFT JOIN web_agg w ON i.i_item_id = w.item_id
LEFT JOIN cust_agg c ON i.i_item_id = c.item_id
LEFT JOIN review_agg r ON i.i_item_id = r.item_id
ORDER BY total_quantity DESC
LIMIT 10
