WITH store_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT pr.pr_item_id,
           COUNT(*) AS review_count,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_count_by_category AS (
    SELECT i.i_category_name,
           COUNT(DISTINCT ss.ss_store_id) AS distinct_store_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_name
)
SELECT i.i_category_name,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity_sold,
       AVG(i.i_price) AS avg_item_price,
       AVG(ra.avg_rating) AS avg_item_rating,
       SUM(COALESCE(ra.review_count, 0)) AS total_reviews,
       COALESCE(sc.distinct_store_count, 0) AS distinct_stores_selling_category
FROM items i
LEFT JOIN store_agg sa ON sa.i_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
LEFT JOIN store_count_by_category sc ON sc.i_category_name = i.i_category_name
GROUP BY i.i_category_name, sc.distinct_store_count
ORDER BY total_quantity_sold DESC
LIMIT 10
