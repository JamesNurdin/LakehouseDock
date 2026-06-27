WITH
    store_sales_agg AS (
        SELECT
            ss_item_id,
            SUM(ss_quantity) AS total_store_quantity,
            COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS total_web_quantity,
            COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
        FROM web_sales
        GROUP BY ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr_item_id,
            AVG(pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    item_customers AS (
        SELECT ss_item_id AS item_id, ss_customer_id AS customer_id FROM store_sales
        UNION ALL
        SELECT ws_item_id AS item_id, ws_customer_id AS customer_id FROM web_sales
    ),
    item_customers_agg AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_total_customers
        FROM item_customers
        GROUP BY item_id
    )
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(ss.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(ws.distinct_web_customers, 0) AS distinct_web_customers,
    COALESCE(ic.distinct_total_customers, 0) AS distinct_total_customers,
    COALESCE(r.avg_rating, 0.0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    (COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0)) AS total_quantity_sold,
    (COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0)) * i.i_price AS total_sales_amount
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN item_customers_agg ic ON ic.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.pr_item_id = i.i_item_id
WHERE i.i_price > 0
ORDER BY total_quantity_sold DESC
LIMIT 50
