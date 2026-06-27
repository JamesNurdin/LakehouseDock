WITH store_sales_enriched AS (
    SELECT
        ss.ss_item_id,
        ss.ss_quantity,
        ss.ss_customer_id,
        ss.ss_store_id,
        i.i_price,
        i.i_category_id,
        i.i_category_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_enriched AS (
    SELECT
        ws.ws_item_id,
        ws.ws_quantity,
        ws.ws_customer_id,
        i.i_price,
        i.i_category_id,
        i.i_category_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
item_reviews_agg AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(ss.se_quantity, 0)) AS store_quantity,
    SUM(COALESCE(ws.we_quantity, 0)) AS web_quantity,
    SUM(COALESCE(ss.se_quantity, 0) * ss.se_price) + SUM(COALESCE(ws.we_quantity, 0) * ws.we_price) AS total_revenue,
    COUNT(DISTINCT COALESCE(ss.se_customer_id, ws.we_customer_id)) AS distinct_customers,
    AVG(ir.avg_rating) AS avg_item_rating,
    SUM(ir.review_count) AS total_reviews
FROM items i
LEFT JOIN (
    SELECT
        ss_item_id AS se_item_id,
        ss_quantity AS se_quantity,
        ss_customer_id AS se_customer_id,
        i_price AS se_price
    FROM store_sales_enriched
) ss ON ss.se_item_id = i.i_item_id
LEFT JOIN (
    SELECT
        ws_item_id AS we_item_id,
        ws_quantity AS we_quantity,
        ws_customer_id AS we_customer_id,
        i_price AS we_price
    FROM web_sales_enriched
) ws ON ws.we_item_id = i.i_item_id
LEFT JOIN item_reviews_agg ir ON ir.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
