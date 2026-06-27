WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM items i
    LEFT JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    LEFT JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name, i.i_price
),
web_item_sales AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM items i
    LEFT JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
    LEFT JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_item_id
),
item_reviews AS (
    SELECT
        i.i_item_id,
        COUNT(pr.pr_review_id) AS review_cnt,
        AVG(pr.pr_rating) AS avg_rating,
        MIN(pr.pr_rating) AS min_rating,
        MAX(pr.pr_rating) AS max_rating
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category_name,
    i.i_name,
    i.i_price,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(s.store_revenue, 0) AS store_revenue,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(w.web_revenue, 0) AS web_revenue,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
    COALESCE(s.store_customer_cnt, 0) + COALESCE(w.web_customer_cnt, 0) AS total_customer_cnt,
    COALESCE(r.review_cnt, 0) AS review_cnt,
    r.avg_rating,
    ROW_NUMBER() OVER (
        PARTITION BY i.i_category_name
        ORDER BY COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) DESC
    ) AS revenue_rank_in_category
FROM items i
LEFT JOIN item_sales s ON s.i_item_id = i.i_item_id
LEFT JOIN web_item_sales w ON w.i_item_id = i.i_item_id
LEFT JOIN item_reviews r ON r.i_item_id = i.i_item_id
WHERE i.i_category_name IS NOT NULL
ORDER BY i.i_category_name, revenue_rank_in_category
LIMIT 100
