WITH store_sales_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT pr.pr_item_id AS item_id,
           COUNT(*) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       COALESCE(SUM(sa.store_quantity), 0) AS total_store_quantity,
       COALESCE(SUM(wa.web_quantity), 0) AS total_web_quantity,
       COALESCE(SUM(sa.store_revenue), 0) + COALESCE(SUM(wa.web_revenue), 0) AS total_revenue,
       COALESCE(SUM(r.review_count), 0) AS total_review_count,
       CASE WHEN SUM(r.review_count) > 0 THEN
            SUM(r.avg_sentiment * r.review_count) / SUM(r.review_count)
            ELSE NULL END AS avg_sentiment
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
