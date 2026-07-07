SELECT
    sr.i_category,
    sr.i_category_id,
    SUM(sr.total_quantity) AS total_quantity_sold,
    AVG(sr.review_sentiment) AS avg_review_sentiment
FROM (
    SELECT
        i.i_category,
        i.i_category_id,
        ss.ss_quantity AS total_quantity,
        pr.pr_sentiment AS review_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id

    UNION ALL

    SELECT
        i.i_category,
        i.i_category_id,
        ws.ws_quantity AS total_quantity,
        pr.pr_sentiment AS review_sentiment
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
) AS sr
GROUP BY sr.i_category, sr.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
