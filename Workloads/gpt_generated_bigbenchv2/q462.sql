WITH
    store_category_sales AS (
        SELECT
            ss_store_id,
            i_category_id,
            i_category_name,
            SUM(ss_quantity) AS store_quantity,
            SUM(ss_quantity * i_price) AS store_revenue,
            COUNT(DISTINCT ss_customer_id) AS store_customer_count
        FROM store_sales
        JOIN items ON store_sales.ss_item_id = items.i_item_id
        GROUP BY ss_store_id, i_category_id, i_category_name
    ),
    web_category_sales AS (
        SELECT
            i_category_id,
            i_category_name,
            SUM(ws_quantity) AS web_quantity,
            SUM(ws_quantity * i_price) AS web_revenue,
            COUNT(DISTINCT ws_customer_id) AS web_customer_count
        FROM web_sales
        JOIN items ON web_sales.ws_item_id = items.i_item_id
        GROUP BY i_category_id, i_category_name
    ),
    category_reviews AS (
        SELECT
            i_category_id,
            AVG(pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews
        JOIN items ON product_reviews.pr_item_id = items.i_item_id
        GROUP BY i_category_id
    )
SELECT
    s.s_store_name,
    s.s_store_id,
    sc.i_category_name,
    sc.store_quantity,
    sc.store_revenue,
    sc.store_customer_count,
    COALESCE(wc.web_quantity, 0) AS web_quantity,
    COALESCE(wc.web_revenue, 0) AS web_revenue,
    COALESCE(wc.web_customer_count, 0) AS web_customer_count,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count
FROM store_category_sales sc
JOIN stores s ON sc.ss_store_id = s.s_store_id
LEFT JOIN web_category_sales wc ON sc.i_category_id = wc.i_category_id
LEFT JOIN category_reviews r ON sc.i_category_id = r.i_category_id
ORDER BY sc.store_quantity DESC
LIMIT 50
