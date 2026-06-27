WITH
    item_sales AS (
        SELECT
            i.i_item_id,
            SUM(ss.ss_quantity) AS store_qty,
            SUM(ss.ss_quantity * i.i_price) AS store_rev,
            COUNT(DISTINCT ss.ss_customer_id) AS store_cust_cnt
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    item_web_sales AS (
        SELECT
            i.i_item_id,
            SUM(ws.ws_quantity) AS web_qty,
            SUM(ws.ws_quantity * i.i_price) AS web_rev,
            COUNT(DISTINCT ws.ws_customer_id) AS web_cust_cnt
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    item_reviews AS (
        SELECT
            i.i_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_cnt
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    category_sales AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) AS total_quantity,
            SUM(COALESCE(s.store_rev, 0) + COALESCE(w.web_rev, 0)) AS total_revenue,
            SUM(COALESCE(r.avg_rating, 0) * COALESCE(r.review_cnt, 0))
                / NULLIF(SUM(COALESCE(r.review_cnt, 0)), 0) AS avg_category_rating
        FROM items i
        LEFT JOIN item_sales s ON i.i_item_id = s.i_item_id
        LEFT JOIN item_web_sales w ON i.i_item_id = w.i_item_id
        LEFT JOIN item_reviews r ON i.i_item_id = r.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    category_customers AS (
        SELECT
            category_id,
            COUNT(DISTINCT cust_id) AS distinct_customers
        FROM (
            SELECT ss.ss_customer_id AS cust_id, i.i_category_id AS category_id
            FROM store_sales ss
            JOIN items i ON ss.ss_item_id = i.i_item_id
            UNION ALL
            SELECT ws.ws_customer_id AS cust_id, i.i_category_id AS category_id
            FROM web_sales ws
            JOIN items i ON ws.ws_item_id = i.i_item_id
        ) u
        GROUP BY category_id
    )
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.total_quantity,
    cs.total_revenue,
    cs.avg_category_rating,
    COALESCE(cc.distinct_customers, 0) AS distinct_customers
FROM category_sales cs
LEFT JOIN category_customers cc ON cs.i_category_id = cc.category_id
ORDER BY cs.total_revenue DESC
LIMIT 10
