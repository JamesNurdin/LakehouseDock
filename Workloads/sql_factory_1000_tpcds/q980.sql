SELECT
   cs.cs_order_number,
   cc.cc_name,
   sm.sm_ship_mode_id,
   cust.c_customer_id,
   cust.c_first_name,
   cust.c_last_name,
   cs.cs_quantity,
   cs.cs_sales_price,
   cs.cs_net_profit,
   cs.cs_ext_discount_amt,
   CASE
      WHEN cs.cs_ext_discount_amt > 500 THEN 'High Discount'
      ELSE 'Normal Discount'
   END AS discount_category,
   PERCENT_RANK() OVER (ORDER BY cs.cs_net_profit DESC) AS profit_percentile,
   NTILE(4) OVER (ORDER BY cs.cs_net_profit DESC) AS profit_quartile,
   ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY cs.cs_net_profit DESC) AS call_center_rank
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
WHERE cs.cs_sold_date_sk BETWEEN 20230101 AND 20231231
ORDER BY profit_percentile DESC
LIMIT 100
