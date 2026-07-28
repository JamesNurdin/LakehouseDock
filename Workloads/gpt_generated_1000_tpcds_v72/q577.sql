WITH billed AS (
   SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state AS cc_state,
      SUM(cs.cs_net_paid) AS billed_sales,
      (SELECT MAX(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk) AS max_ext_price
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer_address ca
     ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE ca.ca_state = 'CA'
     AND EXISTS (
         SELECT 1
         FROM catalog_sales cs3
         WHERE cs3.cs_bill_customer_sk = cs.cs_bill_customer_sk
           AND cs3.cs_net_paid > 1000
        )
   GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_state
),
shipped AS (
   SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state AS cc_state,
      SUM(cs.cs_net_paid) AS shipped_sales,
      (SELECT MIN(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk) AS min_ext_price
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer_address ca
     ON cs.cs_ship_addr_sk = ca.ca_address_sk
   WHERE ca.ca_state = 'NY'
   GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_state
)
SELECT
   combined.cc_name,
   combined.cc_state,
   combined.total_sales,
   combined.price_metric,
   ca_cnt.addr_cnt
FROM (
   SELECT cc_name,
          cc_state,
          billed_sales AS total_sales,
          max_ext_price AS price_metric
   FROM billed
   UNION ALL
   SELECT cc_name,
          cc_state,
          shipped_sales AS total_sales,
          min_ext_price AS price_metric
   FROM shipped
) AS combined
CROSS JOIN LATERAL (
   SELECT COUNT(*) AS addr_cnt
   FROM customer_address ca
   WHERE ca.ca_state = combined.cc_state
) AS ca_cnt
ORDER BY combined.total_sales DESC
LIMIT 100
