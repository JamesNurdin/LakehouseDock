WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    INNER JOIN items i ON ss.ss_item_id = i.i_item_id
    INNER JOIN stores s ON ss.ss_store_id = s.s_store_id
    INNER JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    INNER JOIN items i ON ws.ws_item_id = i.i_item_id
    INNER JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    INNER JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
price_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id, pa.i_category_id) AS category_id,
    COALESCE(sa.i_category, wa.i_category, ra.i_category, pa.i_category) AS category_name,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    ra.avg_sentiment,
    ra.review_count,
    pa.avg_price
FROM store_agg sa
FULL OUTER JOIN web_agg wa ON sa.i_category_id = wa.i_category_id
FULL OUTER JOIN review_agg ra ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
FULL OUTER JOIN price_agg pa ON COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id) = pa.i_category_id
ORDER BY category_id
