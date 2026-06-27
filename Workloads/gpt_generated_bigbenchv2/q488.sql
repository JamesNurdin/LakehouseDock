WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * it.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items it
        ON ss.ss_item_id = it.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * it.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items it
        ON ws.ws_item_id = it.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
customer_item AS (
    SELECT ss.ss_customer_id AS customer_id, ss.ss_item_id AS item_id
    FROM store_sales ss
    UNION
    SELECT ws.ws_customer_id AS customer_id, ws.ws_item_id AS item_id
    FROM web_sales ws
),
customer_counts AS (
    SELECT
        item_id,
        COUNT(DISTINCT customer_id) AS distinct_customer_cnt
    FROM customer_item
    GROUP BY item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    r.avg_rating,
    r.review_count,
    cc.distinct_customer_cnt
FROM items i
LEFT JOIN store_sales_agg sa
    ON i.i_item_id = sa.ss_item_id
LEFT JOIN stores s
    ON sa.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wa
    ON i.i_item_id = wa.ws_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.pr_item_id
LEFT JOIN customer_counts cc
    ON i.i_item_id = cc.item_id
WHERE i.i_category_name IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 20
