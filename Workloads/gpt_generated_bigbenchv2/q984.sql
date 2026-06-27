WITH item_review_agg AS (
    SELECT
        pr_item_id AS item_id,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_store_id AS store_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        SUM(COALESCE(ira.avg_rating * ss.ss_quantity, 0)) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_rating,
        SUM(COALESCE(ws_agg.total_web_quantity, 0)) AS total_web_quantity_for_store_items,
        SUM(COALESCE(ws_agg.total_web_revenue, 0)) AS total_web_revenue_for_store_items
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_review_agg ira
        ON i.i_item_id = ira.item_id
    LEFT JOIN web_sales_agg ws_agg
        ON i.i_item_id = ws_agg.item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(sa.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(sa.distinct_customers, 0) AS distinct_customers,
    COALESCE(sa.weighted_avg_rating, 0) AS weighted_avg_rating,
    COALESCE(sa.total_web_quantity_for_store_items, 0) AS total_web_quantity_for_store_items,
    COALESCE(sa.total_web_revenue_for_store_items, 0) AS total_web_revenue_for_store_items
FROM stores s
LEFT JOIN store_sales_agg sa
    ON s.s_store_id = sa.store_id
ORDER BY total_store_revenue DESC
