WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        ss_store_id,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_customer_id) AS store_customer_count
    FROM store_sales
    GROUP BY ss_item_id, ss_store_id
),
store_sales_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_store_id,
        SUM(ss.store_quantity) AS total_store_quantity,
        SUM(ss.store_customer_count) AS total_store_customers
    FROM items i
    JOIN store_sales_agg ss
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name, ss.ss_store_id
),
store_top AS (
    SELECT
        scc.i_category_id,
        scc.i_category_name,
        s.s_store_name,
        scc.total_store_quantity,
        scc.total_store_customers,
        ROW_NUMBER() OVER (PARTITION BY scc.i_category_id ORDER BY scc.total_store_quantity DESC) AS rn
    FROM store_sales_category scc
    JOIN stores s
        ON s.s_store_id = scc.ss_store_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws_customer_id) AS web_customer_count
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ss.store_quantity, 0) * i.i_price) + SUM(COALESCE(ws.web_quantity, 0) * i.i_price) AS total_revenue,
        SUM(COALESCE(ss.store_customer_count, 0) + COALESCE(ws.web_customer_count, 0)) AS total_customers,
        AVG(COALESCE(r.avg_rating, 0)) AS avg_rating,
        SUM(COALESCE(r.review_count, 0)) AS total_reviews
    FROM items i
    LEFT JOIN (
        SELECT ss_item_id,
               SUM(ss_quantity) AS store_quantity,
               COUNT(DISTINCT ss_customer_id) AS store_customer_count
        FROM store_sales
        GROUP BY ss_item_id
    ) ss
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN web_sales_agg ws
        ON ws.ws_item_id = i.i_item_id
    LEFT JOIN reviews_agg r
        ON r.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    cs.i_category_id,
    cs.i_category_name,
    cs.total_quantity,
    cs.total_revenue,
    cs.total_customers,
    cs.avg_rating,
    cs.total_reviews,
    st.s_store_name AS top_store_name,
    st.total_store_quantity AS top_store_quantity
FROM category_sales cs
LEFT JOIN (
    SELECT i_category_id,
           s_store_name,
           total_store_quantity
    FROM store_top
    WHERE rn = 1
) st
    ON st.i_category_id = cs.i_category_id
ORDER BY cs.total_quantity DESC
LIMIT 10
