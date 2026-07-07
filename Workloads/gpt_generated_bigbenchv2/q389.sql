SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_store_quantity,
    (SELECT SUM(ws.ws_quantity)
     FROM web_sales ws
     JOIN items i_ws ON ws.ws_item_id = i_ws.i_item_id
     WHERE i_ws.i_category = i.i_category) AS total_web_quantity,
    (SELECT AVG(pr.pr_sentiment)
     FROM product_reviews pr
     JOIN items i_pr ON pr.pr_item_id = i_pr.i_item_id
     WHERE i_pr.i_category = i.i_category) AS avg_sentiment
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
GROUP BY s.s_store_name, i.i_category
ORDER BY s.s_store_name, i.i_category
