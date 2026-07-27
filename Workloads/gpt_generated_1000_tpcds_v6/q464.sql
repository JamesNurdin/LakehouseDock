WITH sales_agg AS (
  SELECT
    cs_order_number,
    cs_call_center_sk,
    SUM(cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    MAX(cs_ext_tax) AS max_tax
  FROM tpcds.catalog_sales
  WHERE cs_ext_tax > 30
  GROUP BY cs_order_number, cs_call_center_sk
)
SELECT
  cc.cc_call_center_id,
  CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
  REGEXP_EXTRACT(cc.cc_suite_number, '\\d+') AS suite_number,
  sales_agg.total_profit,
  sales_agg.sales_cnt,
  (SELECT AVG(cr_return_amount)
   FROM tpcds.catalog_returns cr
   WHERE cr.cr_call_center_sk = cc.cc_call_center_sk) AS avg_return_amount,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM tpcds.catalog_returns cr2
      WHERE cr2.cr_order_number = sales_agg.cs_order_number
        AND cr2.cr_reversed_charge > 1000
    ) THEN 'HighReversal' ELSE 'Normal'
  END AS reversal_flag
FROM tpcds.call_center cc
JOIN sales_agg
  ON sales_agg.cs_call_center_sk = cc.cc_call_center_sk
WHERE
  REGEXP_LIKE(cc.cc_name, '^A.*')
  AND CAST(REGEXP_EXTRACT(cc.cc_suite_number, '\\d+') AS integer) > 300
  AND cc.cc_city LIKE 'San%'
  AND SUBSTRING(cc.cc_state, 1, 2) = 'CA'
ORDER BY sales_agg.total_profit DESC
LIMIT 100
