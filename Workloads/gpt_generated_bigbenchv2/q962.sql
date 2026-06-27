WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
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
),
distinct_customers_agg AS (
    SELECT
        combined.i_category_id,
        combined.i_category_name,
        COUNT(DISTINCT combined.cust_id) AS distinct_customers
    FROM (
        SELECT ss.ss_customer_id AS cust_id,
               i.i_category_id,
               i.i_category_name
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT ws.ws_customer_id AS cust_id,
               i.i_category_id,
               i.i_category_name
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ) AS combined
    GROUP BY combined.i_category_id, combined.i_category_name
)
SELECT
    COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id, ca.i_category_id) AS category_id,
    COALESCE(sa.i_category_name, wa.i_category_name, ra.i_category_name, ca.i_category_name) AS category_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    ra.avg_rating,
    ra.review_count,
    COALESCE(ca.distinct_customers, 0) AS distinct_customers
FROM store_sales_agg sa
FULL OUTER JOIN web_sales_agg wa
    ON sa.i_category_id = wa.i_category_id
FULL OUTER JOIN product_reviews_agg ra
    ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
FULL OUTER JOIN distinct_customers_agg ca
    ON COALESCE(sa.i_category_id, wa.i_category_id) = ca.i_category_id
ORDER BY total_revenue DESC
