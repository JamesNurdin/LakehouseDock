WITH
store_agg AS (
    SELECT
        ss_item_id AS i_item_id,
        SUM(ss_quantity) AS store_qty,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id AS i_item_id,
        SUM(ws_quantity) AS web_qty,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    COALESCE(sa.store_qty, 0) AS store_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_qty, 0) AS web_quantity,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    AVG(pr.pr_sentiment) AS avg_sentiment
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY
    i.i_item_id,
    i.i_name,
    i.i_category,
    sa.store_qty,
    sa.store_revenue,
    wa.web_qty,
    wa.web_revenue
ORDER BY total_revenue DESC
LIMIT 10
