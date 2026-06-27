WITH categories AS (
    SELECT DISTINCT i_category_id, i_category_name
    FROM items
),
store_sales_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(i.i_price * ss.ss_quantity) AS store_rev,
        COUNT(DISTINCT ss.ss_customer_id) AS store_cust
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(i.i_price * ws.ws_quantity) AS web_rev,
        COUNT(DISTINCT ws.ws_customer_id) AS web_cust
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cat.i_category_id,
    cat.i_category_name,
    COALESCE(ss.store_qty, 0) AS store_quantity,
    COALESCE(ss.store_rev, 0) AS store_revenue,
    COALESCE(ws.web_qty, 0) AS web_quantity,
    COALESCE(ws.web_rev, 0) AS web_revenue,
    COALESCE(ss.store_cust, 0) + COALESCE(ws.web_cust, 0) AS total_customers,
    COALESCE(rv.avg_rating, 0) AS average_rating,
    COALESCE(rv.review_cnt, 0) AS review_count
FROM categories cat
LEFT JOIN store_sales_by_category ss
    ON cat.i_category_id = ss.i_category_id
   AND cat.i_category_name = ss.i_category_name
LEFT JOIN web_sales_by_category ws
    ON cat.i_category_id = ws.i_category_id
   AND cat.i_category_name = ws.i_category_name
LEFT JOIN reviews_by_category rv
    ON cat.i_category_id = rv.i_category_id
   AND cat.i_category_name = rv.i_category_name
ORDER BY (COALESCE(ss.store_rev, 0) + COALESCE(ws.web_rev, 0)) DESC
LIMIT 20
