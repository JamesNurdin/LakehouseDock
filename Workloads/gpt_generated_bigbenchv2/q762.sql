WITH
item_info AS (
    SELECT i_item_id,
           i_name,
           i_category_id,
           i_category_name,
           i_price,
           i_comp_price,
           i_class_id
    FROM items
),
review_agg AS (
    SELECT pr_item_id,
           avg(pr_rating) AS avg_rating,
           count(*) AS review_cnt
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT ss_item_id,
           sum(ss_quantity) AS store_qty,
           count(*) AS store_txn_cnt
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id,
           sum(ws_quantity) AS web_qty,
           count(*) AS web_txn_cnt
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT
    ii.i_item_id,
    ii.i_name,
    ii.i_category_name,
    ii.i_price,
    ra.avg_rating,
    ra.review_cnt,
    COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0) AS total_quantity_sold,
    COALESCE(ssa.store_txn_cnt, 0) + COALESCE(wsa.web_txn_cnt, 0) AS total_transactions,
    (COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0)) * ii.i_price AS total_sales_amount
FROM item_info ii
LEFT JOIN review_agg ra
    ON ra.pr_item_id = ii.i_item_id
LEFT JOIN store_sales_agg ssa
    ON ssa.ss_item_id = ii.i_item_id
LEFT JOIN web_sales_agg wsa
    ON wsa.ws_item_id = ii.i_item_id
WHERE ra.avg_rating IS NOT NULL
  AND (COALESCE(ssa.store_qty, 0) + COALESCE(wsa.web_qty, 0)) > 0
ORDER BY total_sales_amount DESC
LIMIT 100
