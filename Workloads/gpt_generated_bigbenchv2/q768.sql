WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_name,
        sum(ss.ss_quantity) AS total_store_quantity,
        sum(i.i_price * ss.ss_quantity) AS total_store_revenue,
        count(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_name,
        sum(ws.ws_quantity) AS total_online_quantity,
        sum(i.i_price * ws.ws_quantity) AS total_online_revenue,
        count(DISTINCT ws.ws_customer_id) AS distinct_online_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_name,
        avg(pr.pr_rating) AS avg_rating,
        count(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT
    ss.s_store_name,
    ss.i_category_name AS category_name,
    ss.total_store_quantity,
    ss.total_store_revenue,
    ws.total_online_quantity,
    ws.total_online_revenue,
    r.avg_rating,
    r.review_count,
    ss.distinct_store_customers,
    ws.distinct_online_customers
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.i_category_name = ws.i_category_name
LEFT JOIN reviews_agg r
    ON ss.i_category_name = r.i_category_name
ORDER BY ss.s_store_name, ss.i_category_name
