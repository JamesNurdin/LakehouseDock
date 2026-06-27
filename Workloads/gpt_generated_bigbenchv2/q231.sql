WITH store_sales_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(pr_review_id) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category_name,
       SUM(COALESCE(ssa.store_qty, 0)) AS total_store_quantity,
       SUM(COALESCE(wsa.web_qty, 0)) AS total_web_quantity,
       SUM(COALESCE(ssa.store_qty, 0)) + SUM(COALESCE(wsa.web_qty, 0)) AS total_quantity,
       CASE WHEN SUM(COALESCE(rva.review_cnt, 0)) = 0 THEN NULL
            ELSE SUM(COALESCE(rva.avg_rating * rva.review_cnt, 0)) / SUM(COALESCE(rva.review_cnt, 0))
       END AS avg_category_rating,
       SUM(COALESCE(rva.review_cnt, 0)) AS total_reviews,
       AVG(i.i_price) AS avg_price,
       COUNT(DISTINCT i.i_item_id) AS distinct_items
FROM items i
LEFT JOIN store_sales_agg ssa
    ON ssa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa
    ON wsa.ws_item_id = i.i_item_id
LEFT JOIN reviews_agg rva
    ON rva.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity DESC
LIMIT 10
