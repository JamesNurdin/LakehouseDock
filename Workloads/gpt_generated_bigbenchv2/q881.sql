WITH store_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
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
    s.s_store_name,
    store_agg.i_category_name,
    store_agg.store_quantity,
    COALESCE(web_agg.web_quantity, 0) AS web_quantity,
    store_agg.store_quantity + COALESCE(web_agg.web_quantity, 0) AS total_quantity,
    store_agg.store_customer_cnt,
    COALESCE(web_agg.web_customer_cnt, 0) AS web_customer_cnt,
    store_agg.store_customer_cnt + COALESCE(web_agg.web_customer_cnt, 0) AS total_customers,
    review_agg.avg_rating,
    review_agg.review_cnt
FROM store_agg
JOIN stores s ON store_agg.ss_store_id = s.s_store_id
LEFT JOIN web_agg ON store_agg.i_category_id = web_agg.i_category_id
LEFT JOIN review_agg ON store_agg.i_category_id = review_agg.i_category_id
ORDER BY total_quantity DESC
LIMIT 100
