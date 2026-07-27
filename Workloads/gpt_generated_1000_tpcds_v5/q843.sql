WITH item_returns AS (
   SELECT
       i.i_item_sk,
       i.i_category,
       i.i_item_id,
       i.i_item_desc,
       SUM(sr.sr_return_amt) AS store_return_amt,
       SUM(wr.wr_return_amt) AS web_return_amt
   FROM item i
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_id, '^AAAAAAA[KP]')
     AND i.i_item_desc LIKE '%size%'
   GROUP BY i.i_item_sk, i.i_category, i.i_item_id, i.i_item_desc
),
max_inventory AS (
   SELECT
       inv.inv_item_sk,
       MAX(inv.inv_quantity_on_hand) AS max_qty
   FROM inventory inv
   GROUP BY inv.inv_item_sk
),
joined AS (
   SELECT
       ir.i_item_sk,
       ir.i_category,
       ir.i_item_id,
       ir.i_item_desc,
       ir.store_return_amt,
       ir.web_return_amt,
       mi.max_qty,
       (ir.store_return_amt + ir.web_return_amt) AS total_return_amt,
       regexp_extract(ir.i_item_desc, '(\\d+)', 1) AS first_number_in_desc,
       (SELECT w.w_warehouse_name
        FROM inventory inv2
        JOIN warehouse w ON inv2.inv_warehouse_sk = w.w_warehouse_sk
        WHERE inv2.inv_item_sk = ir.i_item_sk
        ORDER BY inv2.inv_quantity_on_hand DESC
        LIMIT 1) AS top_warehouse_name
   FROM item_returns ir
   JOIN max_inventory mi ON mi.inv_item_sk = ir.i_item_sk
   WHERE mi.max_qty > 100
),
category_agg AS (
   SELECT
       j.i_category,
       j.first_number_in_desc,
       COUNT(DISTINCT j.i_item_id) AS distinct_items,
       SUM(j.total_return_amt) AS category_total_return
   FROM joined j
   GROUP BY j.i_category, j.first_number_in_desc
   HAVING SUM(j.total_return_amt) > 1000
)
SELECT
   ca.i_category,
   CONCAT('Category ', ca.i_category) AS category_label,
   ca.first_number_in_desc,
   ca.distinct_items,
   ca.category_total_return,
   RANK() OVER (ORDER BY ca.category_total_return DESC) AS category_rank
FROM category_agg ca
ORDER BY category_rank
LIMIT 100
