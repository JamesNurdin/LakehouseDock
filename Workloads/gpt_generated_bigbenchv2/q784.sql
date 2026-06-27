WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_distinct_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_ratings AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS i_category_id,
    COALESCE(s.i_category_name, w.i_category_name, r.i_category_name) AS i_category_name,
    s.total_store_quantity,
    s.total_store_revenue,
    w.total_web_quantity,
    w.total_web_revenue,
    r.avg_rating,
    s.store_distinct_customers,
    w.web_distinct_customers
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w
    ON s.i_category_id = w.i_category_id
    AND s.i_category_name = w.i_category_name
FULL OUTER JOIN category_ratings r
    ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
    AND COALESCE(s.i_category_name, w.i_category_name) = r.i_category_name
ORDER BY i_category_id
