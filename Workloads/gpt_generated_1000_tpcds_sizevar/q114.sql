WITH sales_agg AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN store_sales ss
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
   AND ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  WHERE cc.cc_state = 'CA'
    AND cp.cp_type = 'Electronic'
    AND cd.cd_gender = 'M'
    AND hd.hd_income_band_sk BETWEEN 5 AND 8
  GROUP BY s.s_store_id, s.s_store_name, cc.cc_call_center_id, cp.cp_catalog_page_id
)
SELECT
  sa.s_store_id,
  sa.s_store_name,
  sa.cc_call_center_id,
  sa.cp_catalog_page_id,
  sa.catalog_net_profit,
  sa.store_net_profit,
  (sa.catalog_net_profit + sa.store_net_profit) AS total_profit,
  AVG(sa.catalog_net_profit + sa.store_net_profit) OVER (PARTITION BY sa.s_store_id) AS avg_profit_per_store
FROM sales_agg sa
WHERE sa.catalog_net_profit > 10000
  AND EXISTS (
    SELECT 1
    FROM catalog_page cp2
    WHERE cp2.cp_catalog_page_id = sa.cp_catalog_page_id
      AND cp2.cp_department = 'Sports'
  )
ORDER BY total_profit DESC
LIMIT 100
