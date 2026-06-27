WITH store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customer_count,
        AVG(pr.pr_rating) AS avg_store_rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        AVG(pr.pr_rating) AS avg_web_rating
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    LEFT JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    sc.s_store_id,
    sc.s_store_name,
    sc.i_category_name,
    sc.store_quantity,
    sc.store_revenue,
    sc.avg_store_rating,
    sc.distinct_customer_count,
    wc.web_quantity,
    wc.web_revenue,
    wc.avg_web_rating
FROM store_category_sales sc
LEFT JOIN web_category_sales wc
    ON sc.i_category_id = wc.i_category_id
    AND sc.i_category_name = wc.i_category_name
ORDER BY sc.store_revenue DESC
LIMIT 20
