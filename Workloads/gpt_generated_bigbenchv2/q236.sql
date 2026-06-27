SELECT
    s.s_store_name,
    i.i_category_id,
    i.i_category_name,
    SUM(ss.ss_quantity) AS store_quantity,
    SUM(ss.ss_quantity * i.i_price) AS store_revenue,
    (
        SELECT SUM(ws.ws_quantity)
        FROM web_sales ws
        JOIN items i_ws ON ws.ws_item_id = i_ws.i_item_id
        WHERE i_ws.i_category_id = i.i_category_id
    ) AS web_quantity,
    (
        SELECT SUM(ws.ws_quantity * i_ws.i_price)
        FROM web_sales ws
        JOIN items i_ws ON ws.ws_item_id = i_ws.i_item_id
        WHERE i_ws.i_category_id = i.i_category_id
    ) AS web_revenue,
    (
        SELECT AVG(pr.pr_rating)
        FROM product_reviews pr
        JOIN items i_pr ON pr.pr_item_id = i_pr.i_item_id
        WHERE i_pr.i_category_id = i.i_category_id
    ) AS avg_rating,
    (
        SELECT COUNT(pr.pr_review_id)
        FROM product_reviews pr
        JOIN items i_pr ON pr.pr_item_id = i_pr.i_item_id
        WHERE i_pr.i_category_id = i.i_category_id
    ) AS review_count
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_name, i.i_category_id, i.i_category_name
ORDER BY store_revenue DESC, web_revenue DESC
