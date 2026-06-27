WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
customer_counts AS (
    SELECT
        ic.item_id,
        COUNT(DISTINCT ic.customer_id) AS distinct_customer_count
    FROM (
        SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id
        FROM web_sales ws
    ) ic
    GROUP BY ic.item_id
),
sales_combined AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
        COALESCE(sa.total_store_revenue, 0) AS total_store_revenue,
        COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
        COALESCE(wa.total_web_revenue, 0) AS total_web_revenue,
        COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0) AS total_quantity,
        COALESCE(sa.total_store_revenue, 0) + COALESCE(wa.total_web_revenue, 0) AS total_revenue,
        COALESCE(r.review_count, 0) AS review_count,
        r.avg_rating,
        COALESCE(cc.distinct_customer_count, 0) AS distinct_customer_count
    FROM items i
    LEFT JOIN store_sales_agg sa
        ON i.i_item_id = sa.ss_item_id
    LEFT JOIN web_sales_agg wa
        ON i.i_item_id = wa.ws_item_id
    LEFT JOIN reviews_agg r
        ON i.i_item_id = r.pr_item_id
    LEFT JOIN customer_counts cc
        ON i.i_item_id = cc.item_id
)
SELECT
    i_category_id,
    i_category_name,
    i_item_id,
    i_name,
    total_quantity,
    total_revenue,
    distinct_customer_count,
    review_count,
    avg_rating
FROM sales_combined
WHERE total_quantity > 0
ORDER BY i_category_id, total_revenue DESC
LIMIT 20
