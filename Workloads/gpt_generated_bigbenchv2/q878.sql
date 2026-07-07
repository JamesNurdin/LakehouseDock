WITH item_sentiment AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
combined_sales AS (
    SELECT
        ss.ss_store_id AS store_id,
        i.i_item_id,
        i.i_category,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        NULL AS store_id,
        i.i_item_id,
        i.i_category,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_with_sentiment AS (
    SELECT
        cs.store_id,
        cs.i_category,
        cs.quantity,
        cs.revenue,
        its.avg_sentiment,
        its.review_count
    FROM combined_sales cs
    LEFT JOIN item_sentiment its ON cs.i_item_id = its.i_item_id
),
final_agg AS (
    SELECT
        COALESCE(s.s_store_name, 'Web') AS store_name,
        sws.i_category,
        SUM(sws.quantity) AS total_quantity,
        SUM(sws.revenue) AS total_revenue,
        AVG(sws.avg_sentiment) AS avg_sentiment,
        SUM(sws.review_count) AS total_review_count
    FROM sales_with_sentiment sws
    LEFT JOIN stores s ON sws.store_id = s.s_store_id
    GROUP BY COALESCE(s.s_store_name, 'Web'), sws.i_category
)
SELECT
    store_name,
    i_category,
    total_quantity,
    total_revenue,
    avg_sentiment,
    total_review_count
FROM final_agg
ORDER BY total_revenue DESC
LIMIT 10
