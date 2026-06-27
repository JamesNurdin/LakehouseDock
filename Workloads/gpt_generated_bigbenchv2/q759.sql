WITH
store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
rating_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
customer_agg AS (
    SELECT
        cat_id,
        COUNT(DISTINCT cust_id) AS distinct_customers
    FROM (
        SELECT ss.ss_customer_id AS cust_id, i.i_category_id AS cat_id
        FROM store_sales ss
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT ws.ws_customer_id AS cust_id, i.i_category_id AS cat_id
        FROM web_sales ws
        JOIN items i
            ON ws.ws_item_id = i.i_item_id
    ) c
    GROUP BY cat_id
)
SELECT
    COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id, ca.cat_id) AS category_id,
    COALESCE(sa.i_category_name, wa.i_category_name, ra.i_category_name) AS category_name,
    sa.total_store_quantity,
    wa.total_web_quantity,
    sa.total_store_revenue,
    wa.total_web_revenue,
    ra.avg_rating,
    ca.distinct_customers
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.i_category_id = wa.i_category_id
FULL OUTER JOIN rating_agg ra
    ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
FULL OUTER JOIN customer_agg ca
    ON COALESCE(sa.i_category_id, wa.i_category_id) = ca.cat_id
ORDER BY (COALESCE(sa.total_store_revenue, 0) + COALESCE(wa.total_web_revenue, 0)) DESC
LIMIT 10
