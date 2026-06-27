WITH store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS i_item_id,
           SUM(pr_rating) AS total_rating,
           COUNT(*)      AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category_name,
       SUM(COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) AS total_quantity_sold,
       CASE WHEN SUM(COALESCE(r.review_cnt, 0)) = 0 THEN NULL
            ELSE SUM(COALESCE(r.total_rating, 0)) / CAST(SUM(COALESCE(r.review_cnt, 0)) AS double)
       END AS avg_rating,
       CASE WHEN SUM(COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) = 0 THEN NULL
            ELSE SUM(i.i_price * (COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)))
                 / CAST(SUM(COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) AS double)
       END AS avg_price_per_unit_sold
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg   ws ON i.i_item_id = ws.i_item_id
LEFT JOIN review_agg      r  ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity_sold DESC
