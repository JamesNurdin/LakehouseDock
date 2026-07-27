WITH returns_item AS (
   SELECT
       wr.wr_item_sk,
       i.i_brand,
       i.i_category,
       wr.wr_web_page_sk,
       SUM(wr.wr_return_amt) AS total_return_amt,
       AVG(wr.wr_return_quantity) AS avg_return_qty,
       COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN item i
     ON wr.wr_item_sk = i.i_item_sk
   WHERE wr.wr_return_amt > 100
     AND wr.wr_reversed_charge > 50
     AND wr.wr_return_ship_cost > 200
   GROUP BY wr.wr_item_sk, i.i_brand, i.i_category, wr.wr_web_page_sk
),
inventory_agg AS (
   SELECT
       inv.inv_item_sk,
       inv.inv_warehouse_sk,
       SUM(inv.inv_quantity_on_hand) AS total_on_hand,
       MAX(inv.inv_quantity_on_hand) AS max_on_hand
   FROM inventory inv
   WHERE inv.inv_quantity_on_hand > 800
     AND inv.inv_date_sk = 2451074
   GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
)
SELECT
   w.w_warehouse_name,
   w.w_state,
   i_ret.i_brand,
   i_ret.i_category,
   i_ret.total_return_amt,
   i_ret.avg_return_qty,
   inv_agg.total_on_hand,
   inv_agg.max_on_hand,
   COUNT(DISTINCT i_ret.wr_item_sk) AS distinct_items,
   SUM(i_ret.total_return_amt) OVER (PARTITION BY w.w_state ORDER BY i_ret.total_return_amt DESC) AS state_cum_return,
   RANK() OVER (PARTITION BY w.w_state ORDER BY i_ret.total_return_amt DESC) AS state_rank
FROM returns_item i_ret
JOIN inventory_agg inv_agg
  ON i_ret.wr_item_sk = inv_agg.inv_item_sk
JOIN warehouse w
  ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON i_ret.wr_web_page_sk = wp.wp_web_page_sk
WHERE w.w_state = 'CA'
  AND w.w_gmt_offset = -5.00
  AND wp.wp_access_date_sk = 2452623
  AND wp.wp_type = 'product'
GROUP BY
   w.w_warehouse_name,
   w.w_state,
   i_ret.i_brand,
   i_ret.i_category,
   i_ret.total_return_amt,
   i_ret.avg_return_qty,
   inv_agg.total_on_hand,
   inv_agg.max_on_hand
HAVING SUM(i_ret.total_return_amt) > 5000
ORDER BY i_ret.total_return_amt DESC
LIMIT 100
