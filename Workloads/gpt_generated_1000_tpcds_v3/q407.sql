WITH sales_agg AS (
   SELECT
      ca_bill.ca_state AS bill_state,
      sm.sm_ship_mode_id AS sm_ship_mode_id,
      CASE 
         WHEN ws.ws_coupon_amt < 1000 THEN 'Low'
         WHEN ws.ws_coupon_amt < 5000 THEN 'Medium'
         ELSE 'High'
      END AS coupon_bucket,
      SUM(ws.ws_net_profit) AS total_net_profit,
      AVG(ws.ws_ext_sales_price) AS avg_ext_sales_price,
      COUNT(*) AS order_cnt
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   WHERE td.t_am_pm = 'PM'
     AND td.t_sub_shift = 'afternoon'
     AND sm.sm_contract = 'OrDuVy2H'
     AND ws.ws_coupon_amt > 500
     AND ws.ws_quantity >= 2
     AND ca_bill.ca_state = 'CA'
   GROUP BY ca_bill.ca_state,
            sm.sm_ship_mode_id,
            CASE 
               WHEN ws.ws_coupon_amt < 1000 THEN 'Low'
               WHEN ws.ws_coupon_amt < 5000 THEN 'Medium'
               ELSE 'High'
            END
)
SELECT
   bill_state,
   sm_ship_mode_id,
   coupon_bucket,
   total_net_profit,
   avg_ext_sales_price,
   order_cnt,
   RANK() OVER (PARTITION BY bill_state ORDER BY total_net_profit DESC) AS profit_rank_by_state
FROM sales_agg
ORDER BY bill_state, profit_rank_by_state
LIMIT 100
