WITH categories AS (
    SELECT i_category_id, i_category
    FROM items
    GROUP BY i_category_id, i_category
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT c.i_category_id   AS category_id,
       c.i_category      AS category_name,
       r.avg_sentiment,
       r.review_count,
       s.total_store_quantity,
       w.total_web_quantity
FROM categories c
LEFT JOIN review_agg r
       ON c.i_category_id = r.i_category_id AND c.i_category = r.i_category
LEFT JOIN store_sales_agg s
       ON c.i_category_id = s.i_category_id AND c.i_category = s.i_category
LEFT JOIN web_sales_agg w
       ON c.i_category_id = w.i_category_id AND c.i_category = w.i_category
ORDER BY c.i_category
