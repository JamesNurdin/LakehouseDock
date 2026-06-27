WITH store_sales_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category_id,
           i.i_category_name,
           i.i_price,
           i.i_comp_price,
           i.i_class_id,
           COALESCE(s.store_quantity, 0) AS store_quantity,
           COALESCE(w.web_quantity, 0) AS web_quantity,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
           (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) * i.i_price AS total_revenue,
           i.i_price - i.i_comp_price AS price_diff,
           r.avg_rating,
           r.review_count
    FROM items i
    LEFT JOIN store_sales_agg s ON s.item_id = i.i_item_id
    LEFT JOIN web_sales_agg w ON w.item_id = i.i_item_id
    LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
)
SELECT i_sales.i_item_id,
       i_sales.i_name,
       i_sales.i_category_id,
       i_sales.i_category_name,
       i_sales.i_price,
       i_sales.i_comp_price,
       i_sales.i_class_id,
       i_sales.store_quantity,
       i_sales.web_quantity,
       i_sales.total_quantity,
       i_sales.total_revenue,
       i_sales.price_diff,
       i_sales.avg_rating,
       i_sales.review_count,
       ROW_NUMBER() OVER (PARTITION BY i_sales.i_category_name ORDER BY i_sales.total_revenue DESC) AS revenue_rank
FROM item_sales i_sales
WHERE i_sales.total_quantity > 0
ORDER BY i_sales.i_category_name, revenue_rank
