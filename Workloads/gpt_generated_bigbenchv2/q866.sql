WITH
store_sales_detail AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        ss.ss_item_id,
        ss.ss_quantity,
        i.i_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
product_reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
)
SELECT
    s.s_store_name,
    SUM(ssd.ss_quantity) AS total_store_quantity,
    SUM(ssd.ss_quantity * ssd.i_price) AS total_store_sales_amount,
    COUNT(DISTINCT ssd.ss_customer_id) AS distinct_customers,
    AVG(pra.avg_rating) AS avg_item_rating,
    SUM(pra.review_cnt) AS total_review_count,
    SUM(wsa.web_quantity) AS total_web_quantity,
    SUM(wsa.web_sales_amount) AS total_web_sales_amount
FROM store_sales_detail ssd
JOIN stores s ON ssd.ss_store_id = s.s_store_id
LEFT JOIN product_reviews_agg pra ON ssd.ss_item_id = pra.pr_item_id
LEFT JOIN web_sales_agg wsa ON ssd.ss_item_id = wsa.ws_item_id
GROUP BY s.s_store_name
ORDER BY total_store_sales_amount DESC
LIMIT 10
