WITH
    store_sales_agg AS (
        SELECT
            ss_item_id,
            SUM(ss_quantity) AS store_quantity
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws_item_id,
            SUM(ws_quantity) AS web_quantity
        FROM web_sales
        GROUP BY ws_item_id
    ),
    reviews_agg AS (
        SELECT
            pr_item_id,
            COUNT(*)               AS review_count,
            AVG(pr_rating)          AS avg_rating
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    customers_agg AS (
        SELECT
            item_id,
            COUNT(DISTINCT cust_id) AS distinct_customer_count
        FROM (
            SELECT ss_item_id AS item_id, ss_customer_id AS cust_id FROM store_sales
            UNION ALL
            SELECT ws_item_id AS item_id, ws_customer_id AS cust_id FROM web_sales
        ) t
        GROUP BY item_id
    )
SELECT
    i.i_category_id,
    i.i_category_name,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
    (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) * i.i_price AS total_revenue,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating,
    COALESCE(c.distinct_customer_count, 0) AS distinct_customer_count
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg   ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg     r  ON r.pr_item_id = i.i_item_id
LEFT JOIN customers_agg   c  ON c.item_id = i.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
