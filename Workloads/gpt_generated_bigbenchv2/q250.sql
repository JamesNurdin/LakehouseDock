WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
customer_agg AS (
    SELECT
        i_category_id,
        COUNT(DISTINCT cust_id) AS distinct_customers
    FROM (
        SELECT i.i_category_id, ss.ss_customer_id AS cust_id
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT i.i_category_id, ws.ws_customer_id AS cust_id
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ) u
    GROUP BY i_category_id
)

SELECT
    COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id, ca.i_category_id) AS category_id,
    COALESCE(sa.i_category_name, wa.i_category_name, ra.i_category_name) AS category_name,
    COALESCE(sa.store_quantity, 0) AS total_store_quantity,
    COALESCE(wa.web_quantity, 0) AS total_web_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    ca.distinct_customers
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.i_category_id = wa.i_category_id
FULL OUTER JOIN review_agg ra
    ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
FULL OUTER JOIN customer_agg ca
    ON COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id) = ca.i_category_id
ORDER BY total_revenue DESC
LIMIT 20
