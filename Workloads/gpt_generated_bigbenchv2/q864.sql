WITH store_sales_summary AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_store_quantity,
        AVG(i.i_price) AS avg_price,
        SUM(pr.pr_sentiment * ss.ss_quantity) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_sentiment
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores st ON ss.ss_store_id = st.s_store_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_summary AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.i_category,
    s.i_category_id,
    s.total_store_quantity,
    w.total_web_quantity,
    s.avg_price,
    s.weighted_avg_sentiment
FROM store_sales_summary s
LEFT JOIN web_sales_summary w
    ON s.i_category_id = w.i_category_id
ORDER BY s.total_store_quantity DESC
