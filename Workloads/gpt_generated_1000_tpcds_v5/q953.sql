WITH joined AS (
   SELECT
      i1.i_category,
      i1.i_color,
      cs.cs_ext_sales_price,
      cr.cr_return_amount,
      cs.cs_net_profit,
      c_bill.c_customer_sk AS buyer_id,
      c_ship.c_customer_sk AS shipper_id,
      cc_sales.cc_name AS call_center_name,
      w_sales.w_warehouse_name AS warehouse_name,
      t_sales.t_hour AS sale_hour
   FROM catalog_sales cs
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
   JOIN item i1
     ON i1.i_item_sk = cs.cs_item_sk
   JOIN item i2
     ON i2.i_item_sk = cr.cr_item_sk
   JOIN customer c_bill
     ON c_bill.c_customer_sk = cs.cs_bill_customer_sk
   JOIN customer c_ship
     ON c_ship.c_customer_sk = cs.cs_ship_customer_sk
   JOIN customer c_refund
     ON c_refund.c_customer_sk = cr.cr_refunded_customer_sk
   JOIN call_center cc_sales
     ON cc_sales.cc_call_center_sk = cs.cs_call_center_sk
   JOIN call_center cc_ret
     ON cc_ret.cc_call_center_sk = cr.cr_call_center_sk
   JOIN warehouse w_sales
     ON w_sales.w_warehouse_sk = cs.cs_warehouse_sk
   JOIN warehouse w_ret
     ON w_ret.w_warehouse_sk = cr.cr_warehouse_sk
   JOIN time_dim t_sales
     ON t_sales.t_time_sk = cs.cs_sold_time_sk
   JOIN time_dim t_ret
     ON t_ret.t_time_sk = cr.cr_returned_time_sk
   LEFT JOIN web_sales ws
     ON ws.ws_order_number = cs.cs_order_number
   WHERE EXISTS (
         SELECT 1 FROM web_sales ws2
         WHERE ws2.ws_item_sk = cs.cs_item_sk
           AND ws2.ws_sold_date_sk = cs.cs_sold_date_sk
   )
),
agg AS (
   SELECT
      j.i_category,
      j.i_color,
      SUM(j.cs_ext_sales_price) AS total_sales,
      SUM(j.cr_return_amount) AS total_returns,
      COUNT(DISTINCT j.buyer_id) AS distinct_buyers,
      SUM(j.cs_net_profit) AS total_profit
   FROM joined j
   GROUP BY j.i_category, j.i_color
)
SELECT
   a.i_category,
   a.i_color,
   a.total_sales,
   a.total_returns,
   a.distinct_buyers,
   a.total_profit,
   SUM(a.total_sales) OVER (PARTITION BY a.i_category ORDER BY a.total_sales DESC
        ROWS UNBOUNDED PRECEDING) AS cum_sales_by_category
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
