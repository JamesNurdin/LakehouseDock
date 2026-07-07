WITH unified_data AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS qty,
           'store_sales' AS src,
           NULL AS sentiment,
           NULL AS review_id
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS qty,
           'web_sales' AS src,
           NULL AS sentiment,
           NULL AS review_id
    FROM web_sales ws
    UNION ALL
    SELECT pr.pr_item_id AS item_id,
           NULL AS qty,
           'reviews' AS src,
           pr.pr_sentiment AS sentiment,
           pr.pr_review_id AS review_id
    FROM product_reviews pr
)
SELECT i.i_category_id,
       i.i_category,
       SUM(CASE WHEN ud.src = 'store_sales' THEN ud.qty ELSE 0 END) AS total_store_quantity,
       SUM(CASE WHEN ud.src = 'web_sales' THEN ud.qty ELSE 0 END) AS total_web_quantity,
       SUM(CASE WHEN ud.src = 'store_sales' THEN ud.qty * i.i_price ELSE 0 END) AS total_store_revenue,
       SUM(CASE WHEN ud.src = 'web_sales' THEN ud.qty * i.i_price ELSE 0 END) AS total_web_revenue,
       AVG(CASE WHEN ud.src = 'reviews' THEN ud.sentiment END) AS avg_sentiment,
       COUNT(CASE WHEN ud.src = 'reviews' THEN ud.review_id END) AS review_count
FROM unified_data ud
JOIN items i ON ud.item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY i.i_category_id
