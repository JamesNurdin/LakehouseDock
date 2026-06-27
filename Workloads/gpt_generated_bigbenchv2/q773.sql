SELECT
    s.s_store_name,
    sa.i_category_name,
    sa.store_quantity,
    sa.store_sales_amount,
    sa.distinct_customers,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_sales_amount, 0) AS web_sales_amount,
    cr.avg_rating,
    cr.review_count
FROM (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_sales_amount,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
) sa
JOIN stores s ON sa.ss_store_id = s.s_store_id
LEFT JOIN (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
) wa ON sa.i_category_id = wa.i_category_id
LEFT JOIN (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
) cr ON sa.i_category_id = cr.i_category_id
ORDER BY s.s_store_name, sa.i_category_name
