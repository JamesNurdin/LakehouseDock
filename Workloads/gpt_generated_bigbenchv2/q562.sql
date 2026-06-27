WITH review_stats AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_name
),
sales_union AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_customer_id AS cust_id,
        'store' AS channel
    FROM store_sales ss
    JOIN items i
        ON i.i_item_id = ss.ss_item_id

    UNION ALL

    SELECT
        ws.ws_item_id AS i_item_id,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        ws.ws_customer_id AS cust_id,
        'web' AS channel
    FROM web_sales ws
    JOIN items i
        ON i.i_item_id = ws.ws_item_id
),
sales_stats AS (
    SELECT
        i_item_id,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        SUM(CASE WHEN channel = 'store' THEN quantity END) AS store_quantity,
        SUM(CASE WHEN channel = 'web' THEN quantity END) AS web_quantity,
        SUM(CASE WHEN channel = 'store' THEN revenue END) AS store_revenue,
        SUM(CASE WHEN channel = 'web' THEN revenue END) AS web_revenue,
        COUNT(DISTINCT cust_id) AS distinct_customer_cnt
    FROM sales_union
    GROUP BY i_item_id
)
SELECT
    r.i_item_id,
    r.i_name,
    r.i_category_name,
    r.avg_rating,
    r.review_count,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(s.web_quantity, 0) AS web_quantity,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.store_revenue, 0) AS store_revenue,
    COALESCE(s.web_revenue, 0) AS web_revenue,
    COALESCE(s.total_revenue, 0) AS total_revenue,
    COALESCE(s.distinct_customer_cnt, 0) AS distinct_customer_count
FROM review_stats r
LEFT JOIN sales_stats s
    ON s.i_item_id = r.i_item_id
ORDER BY r.avg_rating DESC NULLS LAST, s.total_revenue DESC
LIMIT 10
