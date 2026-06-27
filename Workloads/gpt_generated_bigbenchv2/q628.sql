WITH store_sales_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        COUNT(*) AS review_cnt,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
customer_counts AS (
    SELECT
        item_id,
        COUNT(DISTINCT customer_id) AS distinct_customer_cnt
    FROM (
        SELECT ss.ss_item_id AS item_id, ss.ss_customer_id AS customer_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_id AS item_id, ws.ws_customer_id AS customer_id
        FROM web_sales ws
    ) uc
    GROUP BY item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category_name,
    i.i_price,
    COALESCE(ss.store_qty, 0) AS store_quantity,
    COALESCE(ss.store_revenue, 0) AS store_revenue,
    COALESCE(ws.web_qty, 0) AS web_quantity,
    COALESCE(ws.web_revenue, 0) AS web_revenue,
    COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity,
    COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
    COALESCE(r.review_cnt, 0) AS review_count,
    r.avg_rating,
    COALESCE(c.distinct_customer_cnt, 0) AS distinct_customer_count
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
LEFT JOIN customer_counts c ON i.i_item_id = c.item_id
ORDER BY total_revenue DESC
LIMIT 20
