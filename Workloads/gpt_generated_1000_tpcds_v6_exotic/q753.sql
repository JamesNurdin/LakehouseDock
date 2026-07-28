WITH cs_agg AS (
   SELECT
       cs_call_center_sk,
       SUM(cs_ext_sales_price) AS total_sales,
       COUNT(*) AS order_cnt,
       AVG(cs_list_price) AS avg_list_price
   FROM catalog_sales
   WHERE cs_list_price BETWEEN 50 AND 300
     AND cs_ext_wholesale_cost > 500
   GROUP BY cs_call_center_sk
), qualified_cc AS (
   SELECT
       cc_call_center_sk,
       cc_call_center_id,
       cc_name,
       cc_state,
       cc_sq_ft,
       cc_gmt_offset
   FROM call_center
   WHERE cc_state IN ('CA', 'TX', 'NY')
     AND cc_sq_ft > 0
     AND cc_gmt_offset BETWEEN -5 AND 5
), union_ids AS (
   SELECT cc_call_center_sk FROM qualified_cc WHERE cc_state = 'CA'
   UNION
   SELECT cc_call_center_sk FROM qualified_cc WHERE cc_sq_ft > 1000000
)
SELECT
   qc.cc_call_center_id,
   qc.cc_name,
   qc.cc_state,
   qa.total_sales,
   qa.order_cnt,
   qa.avg_list_price
FROM cs_agg qa
JOIN qualified_cc qc
   ON qa.cs_call_center_sk = qc.cc_call_center_sk
WHERE qc.cc_call_center_sk IN (SELECT cc_call_center_sk FROM union_ids)
  AND EXISTS (
        SELECT 1 FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = qc.cc_call_center_sk
          AND cs2.cs_net_profit > 0
      )
ORDER BY qa.total_sales DESC
LIMIT 100
