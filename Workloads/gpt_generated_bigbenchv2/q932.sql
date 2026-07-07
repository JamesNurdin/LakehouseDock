WITH
    offline_sales_item AS (
        SELECT
            ss.ss_item_id AS item_id,
            SUM(ss.ss_quantity) AS offline_quantity,
            SUM(ss.ss_quantity * i.i_price) AS offline_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id
    ),
    online_sales_item AS (
        SELECT
            ws.ws_item_id AS item_id,
            SUM(ws.ws_quantity) AS online_quantity,
            SUM(ws.ws_quantity * i.i_price) AS online_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    reviews_item AS (
        SELECT
            pr.pr_item_id AS item_id,
            SUM(pr.pr_sentiment) AS sum_sentiment,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    category_sales AS (
        SELECT
            i.i_category_id AS category_id,
            i.i_category AS category_name,
            SUM(COALESCE(off.offline_quantity, 0)) AS total_offline_quantity,
            SUM(COALESCE(off.offline_revenue, 0)) AS total_offline_revenue,
            SUM(COALESCE(onl.online_quantity, 0)) AS total_online_quantity,
            SUM(COALESCE(onl.online_revenue, 0)) AS total_online_revenue,
            SUM(COALESCE(rev.sum_sentiment, 0)) AS total_sentiment,
            SUM(COALESCE(rev.review_count, 0)) AS total_review_count
        FROM items i
        LEFT JOIN offline_sales_item off ON i.i_item_id = off.item_id
        LEFT JOIN online_sales_item onl ON i.i_item_id = onl.item_id
        LEFT JOIN reviews_item rev ON i.i_item_id = rev.item_id
        GROUP BY i.i_category_id, i.i_category
    ),
    category_customers AS (
        SELECT
            i.i_category_id AS category_id,
            i.i_category AS category_name,
            COUNT(DISTINCT cust.customer_id) AS distinct_customers
        FROM (
            SELECT ss.ss_customer_id AS customer_id, ss.ss_item_id AS item_id FROM store_sales ss
            UNION DISTINCT
            SELECT ws.ws_customer_id AS customer_id, ws.ws_item_id AS item_id FROM web_sales ws
        ) cust
        JOIN items i ON cust.item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category
    )
SELECT
    cs.category_id,
    cs.category_name,
    cs.total_offline_quantity,
    cs.total_offline_revenue,
    cs.total_online_quantity,
    cs.total_online_revenue,
    CASE WHEN cs.total_review_count > 0 THEN cs.total_sentiment / cs.total_review_count ELSE NULL END AS avg_review_sentiment,
    cs.total_review_count,
    COALESCE(cc.distinct_customers, 0) AS distinct_customers
FROM category_sales cs
LEFT JOIN category_customers cc ON cs.category_id = cc.category_id
ORDER BY cs.category_id
