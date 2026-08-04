SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_state,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  AVG(cs.cs_net_profit) AS avg_profit,
  COUNT(*) AS transaction_cnt,
  MAX(cs.cs_coupon_amt) AS max_coupon_amt,
  (
    SELECT SUM(cs_sub.cs_quantity)
    FROM catalog_sales cs_sub
    WHERE cs_sub.cs_call_center_sk = cc.cc_call_center_sk
      AND cs_sub.cs_list_price > 200
  ) AS high_price_qty
FROM call_center cc
FULL OUTER JOIN catalog_sales cs
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE
  cc.cc_state = 'CA'
  AND cc.cc_employees > 100
  AND cc.cc_gmt_offset BETWEEN -5.00 AND -4.00
  AND cs.cs_list_price > 100
  AND cs.cs_coupon_amt < 2000
  AND cs.cs_quantity >= 2
GROUP BY
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_state,
  cc.cc_call_center_sk
ORDER BY total_sales DESC
LIMIT 50
