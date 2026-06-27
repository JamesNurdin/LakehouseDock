WITH category_rating AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN stores s
        ON s.s_store_id = ss.ss_store_id
    JOIN items i
        ON i.i_item_id = ss.ss_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_distinct_customers
    FROM web_sales ws
    JOIN items i
        ON i.i_item_id = ws.ws_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    scs.s_store_id,
    scs.s_store_name,
    scs.i_category_id,
    scs.i_category_name,
    scs.store_quantity,
    scs.store_revenue,
    scs.distinct_customers,
    COALESCE(wcs.web_quantity, 0) AS web_quantity,
    COALESCE(wcs.web_revenue, 0) AS web_revenue,
    COALESCE(wcs.web_distinct_customers, 0) AS web_distinct_customers,
    cr.avg_rating,
    cr.review_count
FROM store_category_sales scs
LEFT JOIN web_category_sales wcs
    ON wcs.i_category_id = scs.i_category_id
LEFT JOIN category_rating cr
    ON cr.i_category_id = scs.i_category_id
ORDER BY scs.store_revenue DESC
LIMIT 20
