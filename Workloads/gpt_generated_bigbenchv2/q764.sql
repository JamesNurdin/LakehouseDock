WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_review_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
),
price_agg AS (
    SELECT
        i.i_category,
        AVG(i.i_price) AS avg_item_price
    FROM items i
    GROUP BY i.i_category
)
SELECT
    s.s_store_name,
    ss_agg.i_category,
    ss_agg.total_store_quantity,
    COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
    ra.avg_review_sentiment,
    pa.avg_item_price
FROM store_sales_agg ss_agg
JOIN stores s ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg wa ON ss_agg.i_category = wa.i_category
LEFT JOIN review_agg ra ON ss_agg.i_category = ra.i_category
LEFT JOIN price_agg pa ON ss_agg.i_category = pa.i_category
ORDER BY s.s_store_name, ss_agg.i_category
