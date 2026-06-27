WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT s.s_store_id) AS store_count,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
product_reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    s.i_category_id,
    s.i_category_name,
    s.total_store_quantity,
    w.total_web_quantity,
    (s.total_store_quantity + COALESCE(w.total_web_quantity, 0)) AS total_quantity,
    s.store_count,
    s.store_customer_count,
    w.web_customer_count,
    p.avg_rating,
    p.review_count,
    RANK() OVER (ORDER BY (s.total_store_quantity + COALESCE(w.total_web_quantity, 0)) DESC) AS sales_rank
FROM store_sales_agg s
LEFT JOIN web_sales_agg w
    ON s.i_category_id = w.i_category_id
    AND s.i_category_name = w.i_category_name
LEFT JOIN product_reviews_agg p
    ON s.i_category_id = p.i_category_id
    AND s.i_category_name = p.i_category_name
WHERE (s.total_store_quantity + COALESCE(w.total_web_quantity, 0)) > 0
ORDER BY total_quantity DESC
