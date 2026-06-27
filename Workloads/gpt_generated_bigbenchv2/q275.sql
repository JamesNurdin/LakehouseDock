WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
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
    COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id) AS i_category_id,
    COALESCE(ss.i_category_name, ws.i_category_name, r.i_category_name) AS i_category_name,
    ss.store_quantity,
    ws.web_quantity,
    ss.store_revenue,
    ws.web_revenue,
    (ss.store_quantity + ws.web_quantity) AS total_quantity,
    (ss.store_revenue + ws.web_revenue) AS total_revenue,
    r.avg_rating,
    r.review_count,
    (ss.store_customers + ws.web_customers) AS total_customers
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.i_category_id, ws.i_category_id) = r.i_category_id
ORDER BY total_revenue DESC
LIMIT 20
