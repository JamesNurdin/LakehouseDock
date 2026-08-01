WITH base_sales AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_name,
       cc.cc_city,
       cc.cc_state,
       i.i_item_sk,
       i.i_product_name,
       cs.cs_order_number,
       cs.cs_net_paid,
       cs.cs_net_profit,
       ca.ca_suite_number,
       ca.ca_city AS customer_city,
       regexp_extract(ca.ca_suite_number, '(\\d+)', 1) AS suite_number_extracted,
       regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_number,
       substring(cc.cc_name, 1, 10) AS cc_name_short
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_address ca
     ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{2,}')
     AND ca.ca_suite_number LIKE 'Suite %'
     AND cc.cc_city LIKE 'A%'
),
agg_sales AS (
   SELECT
       bs.cc_call_center_sk,
       bs.cc_name,
       bs.cc_city,
       bs.cc_state,
       bs.cc_name_short,
       SUM(bs.cs_net_paid) AS total_net_paid,
       SUM(bs.cs_net_profit) AS total_net_profit,
       COUNT(DISTINCT bs.cs_order_number) AS num_orders,
       SUM(CASE WHEN TRY_CAST(bs.suite_number_extracted AS INTEGER) > 100 THEN 1 ELSE 0 END) AS high_suite_orders
   FROM base_sales bs
   WHERE EXISTS (
       SELECT 1
       FROM catalog_returns cr
       WHERE cr.cr_call_center_sk = bs.cc_call_center_sk
         AND cr.cr_return_quantity > 0
   )
   GROUP BY
       bs.cc_call_center_sk,
       bs.cc_name,
       bs.cc_city,
       bs.cc_state,
       bs.cc_name_short
   HAVING
       SUM(bs.cs_net_profit) > (
           SELECT AVG(total_profit)
           FROM (
               SELECT SUM(cs2.cs_net_profit) AS total_profit
               FROM catalog_sales cs2
               JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
               GROUP BY cc2.cc_call_center_sk
           ) sub
       )
)
SELECT
   cc_call_center_sk,
   cc_name,
   cc_name_short,
   concat(cc_city, ', ', cc_state) AS location,
   total_net_paid,
   total_net_profit,
   num_orders,
   high_suite_orders,
   ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY profit_rank
LIMIT 100
