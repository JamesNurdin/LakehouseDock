WITH web_qty AS (
    SELECT i2.i_category_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i2 ON ws.ws_item_id = i2.i_item_id
    GROUP BY i2.i_category_id
),
category_rating AS (
    SELECT i3.i_category_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i3 ON pr.pr_item_id = i3.i_item_id
    GROUP BY i3.i_category_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ss.ss_quantity) AS store_quantity,
    COALESCE(wq.web_quantity, 0) AS web_quantity,
    COALESCE(cr.avg_rating, 0) AS avg_rating
FROM store_sales ss
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN customers c
    ON ss.ss_customer_id = c.c_customer_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_qty wq
    ON i.i_category_id = wq.i_category_id
LEFT JOIN category_rating cr
    ON i.i_category_id = cr.i_category_id
WHERE c.c_name LIKE 'A%'
GROUP BY s.s_store_name,
         i.i_category_name,
         wq.web_quantity,
         cr.avg_rating
ORDER BY store_quantity DESC,
         distinct_customers DESC
