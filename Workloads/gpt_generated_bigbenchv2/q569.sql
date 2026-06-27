WITH rating_by_category AS (
    SELECT
        i.i_category_id   AS category_id,
        i.i_category_name AS category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_sales_agg AS (
    SELECT
        i.i_category_id   AS category_id,
        i.i_category_name AS category_name,
        'store'           AS channel,
        SUM(ss.ss_quantity)                     AS total_quantity,
        SUM(ss.ss_quantity * i.i_price)         AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id)       AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id   AS category_id,
        i.i_category_name AS category_name,
        'web'             AS channel,
        SUM(ws.ws_quantity)                     AS total_quantity,
        SUM(ws.ws_quantity * i.i_price)         AS total_revenue,
        COUNT(DISTINCT ws.ws_customer_id)       AS distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    sa.category_id,
    sa.category_name,
    sa.channel,
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customers,
    rb.avg_rating
FROM (
    SELECT
        category_id,
        category_name,
        channel,
        total_quantity,
        total_revenue,
        distinct_customers
    FROM store_sales_agg
    UNION ALL
    SELECT
        category_id,
        category_name,
        channel,
        total_quantity,
        total_revenue,
        distinct_customers
    FROM web_sales_agg
) sa
LEFT JOIN rating_by_category rb
    ON sa.category_id = rb.category_id
ORDER BY sa.total_revenue DESC
LIMIT 20
