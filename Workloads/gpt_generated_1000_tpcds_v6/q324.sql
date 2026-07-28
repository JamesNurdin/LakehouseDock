SELECT i_class, total_return_amt, qty_category, orders_cnt
FROM (
   SELECT i.i_class,
          SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
          CASE WHEN SUM(wr.wr_return_quantity) >= 20 THEN 'HighQty' ELSE 'LowQty' END AS qty_category,
          COUNT(DISTINCT wr.wr_order_number) AS orders_cnt
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE i.i_class = 'furniture'
     AND hd.hd_vehicle_count >= 0
   GROUP BY i.i_class

   UNION ALL

   SELECT i.i_class,
          SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
          CASE WHEN SUM(wr.wr_return_quantity) >= 20 THEN 'HighQty' ELSE 'LowQty' END AS qty_category,
          COUNT(DISTINCT wr.wr_order_number) AS orders_cnt
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE i.i_class = 'shirts'
     AND hd.hd_dep_count < 5
   GROUP BY i.i_class
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
