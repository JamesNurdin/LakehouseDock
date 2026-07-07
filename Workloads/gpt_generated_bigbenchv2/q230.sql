WITH item_sentiment AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_revenue AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
),
store_sentiment AS (
    SELECT
        ss.ss_store_id,
        SUM(ss.ss_quantity * isent.avg_sentiment) / SUM(ss.ss_quantity) AS weighted_avg_sentiment
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN item_sentiment isent
        ON isent.pr_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(r.total_revenue, 0) AS total_revenue,
    COALESCE(r.total_quantity, 0) AS total_quantity,
    sent.weighted_avg_sentiment
FROM stores s
LEFT JOIN store_revenue r
    ON s.s_store_id = r.ss_store_id
LEFT JOIN store_sentiment sent
    ON s.s_store_id = sent.ss_store_id
ORDER BY total_revenue DESC
LIMIT 10
