WITH raw AS (
   SELECT
       cc.cc_name,
       cc.cc_state,
       cp.cp_department,
       i.i_category,
       i.i_manufact_id,
       i.i_size,
       sm.sm_type,
       sm.sm_carrier,
       td_sales.t_hour,
       cs.cs_order_number,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.cs_ext_discount_amt,
       cs.cs_net_profit,
       sr.sr_return_amt,
       sr.sr_return_quantity,
       sr.sr_ticket_number,
       cr.cr_return_amount
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim td_sales ON cs.cs_sold_time_sk = td_sales.t_time_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
   LEFT JOIN time_dim td_store ON sr.sr_return_time_sk = td_store.t_time_sk
   LEFT JOIN time_dim td_return ON cr.cr_returned_time_sk = td_return.t_time_sk
   JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
   LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
   LEFT JOIN customer c_cr_ref ON cr.cr_refunded_customer_sk = c_cr_ref.c_customer_sk
   LEFT JOIN customer_address ca_cr_ref ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk
   LEFT JOIN customer c_cr_ret ON cr.cr_returning_customer_sk = c_cr_ret.c_customer_sk
   LEFT JOIN customer_address ca_cr_ret ON cr.cr_returning_addr_sk = ca_cr_ret.ca_address_sk
   LEFT JOIN call_center cc_cr ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
   LEFT JOIN catalog_page cp_cr ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
   LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
   LEFT JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
),
agg AS (
   SELECT
       cc_name,
       cp_department,
       i_category,
       sm_type,
       t_hour,
       COUNT(DISTINCT cs_order_number) AS distinct_orders,
       SUM(cs_quantity) AS total_quantity,
       SUM(cs_net_paid) AS total_net_paid,
       AVG(cs_ext_discount_amt) AS avg_discount,
       SUM(CASE WHEN cs_net_profit > 0 THEN cs_net_profit ELSE 0 END) AS total_positive_profit,
       SUM(CASE WHEN cs_net_profit <= 0 THEN cs_net_profit ELSE 0 END) AS total_negative_profit,
       SUM(sr_return_amt) AS total_store_return_amount,
       COUNT(DISTINCT sr_ticket_number) AS distinct_store_returns
   FROM raw
   WHERE i_manufact_id IN (214, 630)
     AND i_size = 'large'
     AND cp_department = 'Electronics'
     AND cc_state = 'CA'
     AND sm_carrier = 'FedEx'
     AND t_hour BETWEEN 9 AND 17
     AND cs_quantity > 1
     AND sr_return_quantity > 0
   GROUP BY
       cc_name,
       cp_department,
       i_category,
       sm_type,
       t_hour
)
SELECT
    cc_name,
    cp_department,
    i_category,
    sm_type,
    t_hour,
    distinct_orders,
    total_quantity,
    total_net_paid,
    avg_discount,
    total_positive_profit,
    total_negative_profit,
    total_store_return_amount,
    distinct_store_returns,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS avg_global_return_amount,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_net_paid DESC) AS dept_net_paid_rank,
    SUM(total_net_paid) OVER (PARTITION BY i_category) AS category_total_net_paid
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
