WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_sales_amount,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
product_reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    ss.s_store_name,
    ss.i_category_name,
    ss.store_quantity,
    ss.store_sales_amount,
    ws.web_quantity,
    ws.web_sales_amount,
    pr.avg_rating,
    pr.review_count,
    ss.distinct_customers
FROM store_sales_agg ss
JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
   AND ss.i_category_name = ws.i_category_name
JOIN product_reviews_agg pr
    ON ss.i_category_id = pr.i_category_id
   AND ss.i_category_name = pr.i_category_name
ORDER BY ss.store_sales_amount DESC, ws.web_sales_amount DESC
LIMIT 100
