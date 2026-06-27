WITH
store_agg AS (
    SELECT
        ss_item_id AS i_item_id,
        SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id AS i_item_id,
        SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id AS i_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0)) AS total_quantity_sold,
    SUM(i.i_price * (COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0))) AS total_revenue,
    CASE
        WHEN SUM(r.review_cnt) = 0 THEN NULL
        ELSE SUM(r.avg_rating * r.review_cnt) / SUM(r.review_cnt)
    END AS weighted_avg_rating,
    SUM(r.review_cnt) AS total_review_count
FROM items i
LEFT JOIN store_agg s ON s.i_item_id = i.i_item_id
LEFT JOIN web_agg w ON w.i_item_id = i.i_item_id
LEFT JOIN review_agg r ON r.i_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 10
