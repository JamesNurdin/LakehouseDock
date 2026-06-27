WITH sales_union AS (
    SELECT
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION ALL
    SELECT
        CAST(NULL AS BIGINT) AS store_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
),

sales_agg AS (
    SELECT
        su.store_id,
        i.i_item_id AS item_id,
        i.i_category_name,
        i.i_name,
        i.i_price,
        SUM(su.quantity) AS total_quantity,
        SUM(su.quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT su.customer_id) AS distinct_customers
    FROM sales_union su
    JOIN items i
        ON su.item_id = i.i_item_id
    GROUP BY su.store_id, i.i_item_id, i.i_category_name, i.i_name, i.i_price
),

review_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)

SELECT
    COALESCE(st.s_store_name, 'Online') AS store_name,
    sa.i_category_name,
    sa.i_name,
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customers,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating
FROM sales_agg sa
LEFT JOIN stores st
    ON sa.store_id = st.s_store_id
LEFT JOIN review_agg r
    ON sa.item_id = r.pr_item_id
ORDER BY sa.total_quantity DESC
LIMIT 50
