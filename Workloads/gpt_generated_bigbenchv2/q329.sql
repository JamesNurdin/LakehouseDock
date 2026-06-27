WITH store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
reviews_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
    SUM(COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0)) AS total_revenue,
    AVG(r.avg_rating) AS avg_item_rating,
    SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg sa
    ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa
    ON i.i_item_id = wa.i_item_id
LEFT JOIN reviews_agg r
    ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity DESC
LIMIT 10
