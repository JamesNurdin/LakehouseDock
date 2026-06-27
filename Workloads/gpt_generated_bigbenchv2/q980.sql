WITH store_sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(i.i_price * ss.ss_quantity) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_name, i.i_category_name
),
web_sales_agg AS (
    SELECT
        'Online' AS store_name,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(i.i_price * ws.ws_quantity) AS total_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
combined_sales AS (
    SELECT
        store_name,
        i_category_name,
        total_quantity,
        total_revenue,
        distinct_customers
    FROM store_sales_agg
    UNION ALL
    SELECT
        store_name,
        i_category_name,
        total_quantity,
        total_revenue,
        distinct_customers
    FROM web_sales_agg
),
category_rating AS (
    SELECT
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_name
),
sales_with_rating AS (
    SELECT
        cs.store_name,
        cs.i_category_name,
        cs.total_quantity,
        cs.total_revenue,
        cr.avg_rating,
        cs.distinct_customers
    FROM combined_sales cs
    LEFT JOIN category_rating cr ON cs.i_category_name = cr.i_category_name
),
ranked_sales AS (
    SELECT
        swr.store_name,
        swr.i_category_name,
        swr.total_quantity,
        swr.total_revenue,
        swr.avg_rating,
        swr.distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY swr.i_category_name ORDER BY swr.total_revenue DESC) AS revenue_rank
    FROM sales_with_rating swr
)
SELECT
    store_name,
    i_category_name,
    total_quantity,
    total_revenue,
    avg_rating,
    distinct_customers,
    revenue_rank
FROM ranked_sales
ORDER BY i_category_name, revenue_rank
