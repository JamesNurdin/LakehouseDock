WITH
    store_agg AS (
        SELECT ss_item_id AS item_id,
               SUM(ss_quantity) AS store_qty,
               COUNT(DISTINCT ss_customer_id) AS store_customer_cnt,
               COUNT(DISTINCT ss_store_id) AS store_cnt
        FROM store_sales
        GROUP BY ss_item_id
    ),
    web_agg AS (
        SELECT ws_item_id AS item_id,
               SUM(ws_quantity) AS web_qty,
               COUNT(DISTINCT ws_customer_id) AS web_customer_cnt
        FROM web_sales
        GROUP BY ws_item_id
    ),
    item_sales AS (
        SELECT i.i_item_id,
               i.i_name,
               i.i_category_id,
               i.i_category_name,
               i.i_price,
               COALESCE(sa.store_qty, 0) AS store_qty,
               COALESCE(wa.web_qty, 0) AS web_qty,
               COALESCE(sa.store_customer_cnt, 0) AS store_customer_cnt,
               COALESCE(wa.web_customer_cnt, 0) AS web_customer_cnt,
               COALESCE(sa.store_cnt, 0) AS store_cnt
        FROM items i
        LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
        LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
    ),
    review_agg AS (
        SELECT pr_item_id AS item_id,
               AVG(pr_rating) AS avg_rating
        FROM product_reviews
        GROUP BY pr_item_id
    )
SELECT
    i_sales.i_item_id,
    i_sales.i_name,
    i_sales.i_category_name,
    (i_sales.store_qty + i_sales.web_qty) AS total_quantity_sold,
    (i_sales.store_qty + i_sales.web_qty) * i_sales.i_price AS total_revenue,
    i_sales.store_qty,
    i_sales.web_qty,
    i_sales.store_customer_cnt + i_sales.web_customer_cnt AS distinct_customer_count,
    i_sales.store_cnt AS distinct_store_count,
    COALESCE(r.avg_rating, 0) AS average_rating
FROM item_sales i_sales
LEFT JOIN review_agg r ON r.item_id = i_sales.i_item_id
ORDER BY total_revenue DESC
LIMIT 10
