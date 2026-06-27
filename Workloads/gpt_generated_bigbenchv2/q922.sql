WITH item_price AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        ss.ss_quantity,
        i.i_price,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_item_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
store_agg AS (
    SELECT
        ip.ss_store_id,
        SUM(ip.ss_quantity) AS total_quantity,
        SUM(ip.revenue) AS total_revenue,
        COUNT(DISTINCT ip.ss_customer_id) AS distinct_customers
    FROM item_price ip
    GROUP BY ip.ss_store_id
),
item_avg_rating AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_rating AS (
    SELECT
        ip.ss_store_id,
        SUM(ip.ss_quantity * COALESCE(ir.avg_rating, 0)) AS weighted_rating_sum,
        SUM(ip.ss_quantity) AS rating_quantity_sum
    FROM item_price ip
    LEFT JOIN item_avg_rating ir ON ip.ss_item_id = ir.i_item_id
    GROUP BY ip.ss_store_id
)
SELECT
    s.s_store_name,
    sa.total_quantity,
    sa.total_revenue,
    sa.distinct_customers,
    CASE WHEN sr.rating_quantity_sum > 0 THEN sr.weighted_rating_sum / sr.rating_quantity_sum ELSE NULL END AS avg_item_rating
FROM store_agg sa
JOIN stores s ON sa.ss_store_id = s.s_store_id
JOIN store_rating sr ON sa.ss_store_id = sr.ss_store_id
ORDER BY sa.total_revenue DESC
LIMIT 100
