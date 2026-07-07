WITH store_agg AS (
    SELECT
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    GROUP BY
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_store_id
),
web_agg AS (
    SELECT
        ws.ws_customer_id,
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    GROUP BY
        ws.ws_customer_id,
        ws.ws_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY
        pr.pr_item_id
)
SELECT
    i.i_category,
    s.s_store_name,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(sa.total_store_quantity) AS total_store_quantity,
    COALESCE(SUM(wa.total_web_quantity), 0) AS total_web_quantity,
    AVG(ra.avg_sentiment) AS avg_sentiment,
    AVG(i.i_price) AS avg_price
FROM store_agg sa
JOIN customers c ON sa.ss_customer_id = c.c_customer_id
JOIN items i ON sa.ss_item_id = i.i_item_id
JOIN stores s ON sa.ss_store_id = s.s_store_id
LEFT JOIN web_agg wa ON wa.ws_customer_id = c.c_customer_id AND wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY
    i.i_category,
    s.s_store_name
ORDER BY
    total_store_quantity DESC
LIMIT 10
