WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS store_unique_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_unique_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(pr.pr_rating) AS rating_sum,
        COUNT(pr.pr_review_id) AS rating_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity,
    SUM(COALESCE(ss.store_revenue, 0.0) + COALESCE(ws.web_revenue, 0.0)) AS total_revenue,
    CASE
        WHEN SUM(COALESCE(r.rating_count, 0)) > 0
        THEN SUM(COALESCE(r.rating_sum, 0)) / SUM(COALESCE(r.rating_count, 0))
        ELSE NULL
    END AS avg_rating,
    SUM(COALESCE(ss.store_unique_customers, 0) + COALESCE(ws.web_unique_customers, 0)) AS total_unique_customers,
    SUM(COALESCE(r.rating_count, 0)) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
