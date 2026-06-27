WITH
    categories AS (
        SELECT DISTINCT i.i_category_id,
                        i.i_category_name
        FROM items i
    ),
    store_agg AS (
        SELECT i.i_category_id,
               i.i_category_name,
               sum(ss.ss_quantity) AS store_total_quantity,
               sum(ss.ss_quantity * i.i_price) AS store_total_revenue,
               count(DISTINCT ss.ss_customer_id) AS distinct_customer_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    web_agg AS (
        SELECT i.i_category_id,
               i.i_category_name,
               sum(ws.ws_quantity) AS web_total_quantity,
               sum(ws.ws_quantity * i.i_price) AS web_total_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    rating_agg AS (
        SELECT i.i_category_id,
               i.i_category_name,
               avg(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    )
SELECT c.i_category_id,
       c.i_category_name,
       sa.store_total_quantity,
       sa.store_total_revenue,
       wa.web_total_quantity,
       wa.web_total_revenue,
       ra.avg_rating,
       sa.distinct_customer_count
FROM categories c
LEFT JOIN store_agg sa
    ON c.i_category_id = sa.i_category_id
   AND c.i_category_name = sa.i_category_name
LEFT JOIN web_agg wa
    ON c.i_category_id = wa.i_category_id
   AND c.i_category_name = wa.i_category_name
LEFT JOIN rating_agg ra
    ON c.i_category_id = ra.i_category_id
   AND c.i_category_name = ra.i_category_name
ORDER BY sa.store_total_revenue DESC NULLS LAST
