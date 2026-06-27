WITH store_sales_agg AS (
        SELECT ss_item_id AS item_id,
               SUM(ss_quantity) AS store_qty
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_sales_agg AS (
        SELECT ws_item_id AS item_id,
               SUM(ws_quantity) AS web_qty
        FROM web_sales
        GROUP BY ws_item_id
    ),
    reviews_agg AS (
        SELECT pr_item_id AS item_id,
               COUNT(*) AS review_cnt,
               AVG(pr_rating) AS avg_rating
        FROM product_reviews
        GROUP BY pr_item_id
    ),
    item_sales AS (
        SELECT i.i_item_id,
               i.i_name,
               i.i_category_name,
               i.i_price,
               COALESCE(ss.store_qty, 0) AS store_qty,
               COALESCE(ws.web_qty, 0) AS web_qty,
               COALESCE(r.review_cnt, 0) AS review_cnt,
               r.avg_rating
        FROM items i
        LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.item_id
        LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.item_id
        LEFT JOIN reviews_agg r ON i.i_item_id = r.item_id
    )
SELECT i_item_id,
       i_name,
       i_category_name,
       i_price,
       store_qty,
       web_qty,
       (store_qty + web_qty) AS total_qty,
       (store_qty + web_qty) * i_price AS total_revenue,
       review_cnt,
       avg_rating,
       RANK() OVER (PARTITION BY i_category_name ORDER BY (store_qty + web_qty) * i_price DESC) AS category_revenue_rank
FROM item_sales
WHERE (store_qty + web_qty) > 0
ORDER BY total_revenue DESC
LIMIT 20
