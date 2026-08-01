WITH joined_data AS (
  SELECT DISTINCT
    cs.cs_order_number,
    cs.cs_sales_price,
    cs.cs_quantity,
    cs.cs_net_profit,
    cc.cc_name,
    cc.cc_state,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_income_band_sk,
    ca.ca_state AS cust_state,
    s.s_store_name,
    sr.sr_fee,
    sr.sr_refunded_cash,
    cr.cr_return_amount
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN store_returns sr ON cs.cs_bill_customer_sk = sr.sr_customer_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE cc.cc_state = 'CA'
    AND cs.cs_sales_price > 50
    AND (sr.sr_fee < 20 OR sr.sr_fee IS NULL)
    AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
    )
)
SELECT
  jd.s_store_name,
  jd.cc_name,
  SUM(jd.cs_net_profit) AS total_net_profit,
  SUM(COALESCE(jd.cr_return_amount, 0)) AS total_return_amount,
  COUNT(DISTINCT jd.c_customer_id) AS distinct_customers,
  RANK() OVER (ORDER BY SUM(jd.cs_net_profit) DESC) AS profit_rank
FROM joined_data jd
GROUP BY jd.s_store_name, jd.cc_name
ORDER BY profit_rank
LIMIT 100
