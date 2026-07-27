WITH base AS (
   SELECT
       cc.cc_name,
       i.i_category,
       sm.sm_type,
       td.t_sub_shift,
       cs.cs_net_profit,
       cs.cs_order_number,
       cs.cs_quantity,
       cr.cr_return_amount,
       sr.sr_return_amt,
       ws.ws_net_paid,
       cust_bill.c_email_address
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim td
     ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer cust_bill
     ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
   JOIN customer_address ca_bill
     ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN web_sales ws
     ON ws.ws_order_number = cs.cs_order_number
   WHERE td.t_sub_shift = 'morning'
     AND i.i_category = 'Sports'
     AND sm.sm_type = 'AIR'
     AND cc.cc_state = 'CA'
     AND cust_bill.c_email_address LIKE '%@%.com'
     AND cs.cs_quantity > 2
     AND EXISTS (
         SELECT 1 FROM web_sales ws2
         WHERE ws2.ws_order_number = cs.cs_order_number
           AND ws2.ws_quantity > 5
     )
),
agg AS (
   SELECT
       cc_name,
       i_category,
       sm_type,
       t_sub_shift,
       SUM(cs_net_profit) AS total_profit,
       COUNT(DISTINCT cs_order_number) AS order_cnt
   FROM base
   GROUP BY cc_name, i_category, sm_type, t_sub_shift
)
SELECT
    cc_name,
    i_category,
    sm_type,
    t_sub_shift,
    total_profit,
    order_cnt
FROM agg
WHERE total_profit > (
    SELECT AVG(total_profit) FROM agg
)
ORDER BY total_profit DESC
LIMIT 100
