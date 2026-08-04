WITH sampled_wr AS (
   SELECT * FROM web_returns TABLESAMPLE BERNOULLI (10)
),
intersect_items AS (
   SELECT i.i_item_id
   FROM sampled_wr wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   LEFT JOIN LATERAL (
       SELECT i.i_brand || ' ' || i.i_class AS brand_class
   ) bc ON true
   WHERE wr.wr_return_amt > (
           SELECT MAX(i2.i_current_price)
           FROM item i2
           WHERE i2.i_category = 'shirts'
         )
     AND d.d_day_name = 'Friday'
   GROUP BY i.i_item_id
   HAVING SUM(wr.wr_return_quantity) > 5

   INTERSECT

   SELECT i.i_item_id
   FROM sampled_wr wr2
   JOIN item i ON wr2.wr_item_sk = i.i_item_sk
   JOIN household_demographics hd ON wr2.wr_returning_hdemo_sk = hd.hd_demo_sk
   JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
   LEFT JOIN LATERAL (
       SELECT i.i_brand || ' ' || i.i_class AS brand_class
   ) bc2 ON true
   WHERE wr2.wr_fee > (
           SELECT MIN(wr3.wr_fee)
           FROM web_returns wr3
           WHERE wr3.wr_returned_date_sk = d2.d_date_sk
         )
     AND hd.hd_vehicle_count >= 1
   GROUP BY i.i_item_id
   HAVING COUNT(DISTINCT hd.hd_demo_sk) >= 1
),
full_cc_cust AS (
   SELECT cc.cc_call_center_id,
          cc.cc_city,
          d_cc.d_date,
          c.c_customer_id,
          c.c_first_name,
          c.c_last_name
   FROM call_center cc
   JOIN date_dim d_cc ON cc.cc_open_date_sk = d_cc.d_date_sk
   FULL OUTER JOIN customer c ON c.c_first_sales_date_sk = d_cc.d_date_sk
)
SELECT
   ii.i_item_id,
   fc.cc_call_center_id,
   fc.c_customer_id,
   ROW_NUMBER() OVER (ORDER BY ii.i_item_id) AS row_num
FROM intersect_items ii
FULL OUTER JOIN full_cc_cust fc ON 1 = 1
ORDER BY ii.i_item_id
LIMIT 100
