WITH store_sales_agg AS ( 
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS ( 
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS total_web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS ( 
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       i.i_category_id,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       COALESCE(SUM(sa.total_store_qty), 0) AS total_store_quantity,
       COALESCE(SUM(wa.total_web_qty), 0) AS total_web_quantity,
       COALESCE(AVG(ra.avg_sentiment), NULL) AS avg_review_sentiment,
       COALESCE(SUM(ra.review_count), 0) AS total_reviews,
       AVG(i.i_price) AS avg_item_price
FROM items i
LEFT JOIN store_sales_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_sales_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN reviews_agg ra ON i.i_item_id = ra.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY (total_store_quantity + total_web_quantity) DESC
LIMIT 10
