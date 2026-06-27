SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(CASE WHEN s.channel = 'store' THEN s.quantity ELSE 0 END) AS total_store_quantity,
    SUM(CASE WHEN s.channel = 'web'   THEN s.quantity ELSE 0 END) AS total_web_quantity,
    SUM(s.revenue) AS total_revenue,
    SUM(pr.pr_rating) AS total_rating_sum,
    COUNT(pr.pr_rating) AS total_rating_count,
    CASE WHEN COUNT(pr.pr_rating) > 0
         THEN SUM(pr.pr_rating) * 1.0 / COUNT(pr.pr_rating)
         ELSE NULL
    END AS avg_rating,
    COUNT(DISTINCT s.customer_id) AS distinct_customers
FROM (
    SELECT
        ss.ss_item_id AS i_item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id,
        'store' AS channel,
        i.i_price * ss.ss_quantity AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        ws.ws_item_id AS i_item_id,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id,
        'web' AS channel,
        i.i_price * ws.ws_quantity AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
) s
JOIN items i ON s.i_item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
