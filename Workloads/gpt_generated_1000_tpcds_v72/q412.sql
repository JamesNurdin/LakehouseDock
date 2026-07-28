/*
Goal: Analyze profitability by call‑center city and household buying potential for sales where the call‑center name matches a pattern and the catalog page description contains a keyword. The query extracts the first word of the call‑center name via a lateral join, filters with REGEXP_LIKE, LIKE and substring logic, includes a correlated scalar subquery for the average profit of the call‑center, uses a DISTINCT in an EXISTS subquery, aggregates results and orders by total profit.
*/
SELECT
  CONCAT(cc.cc_city, '-', cc.cc_state) AS city_state,
  name_l.name_first_word,
  hd.hd_buy_potential,
  COUNT(*) AS sales_count,
  SUM(cs.cs_net_profit) AS total_profit,
  AVG(cs.cs_ext_tax) AS avg_tax,
  (
    SELECT AVG(cs_inner.cs_net_profit)
    FROM catalog_sales cs_inner
    WHERE cs_inner.cs_call_center_sk = cc.cc_call_center_sk
  ) AS avg_center_profit,
  CASE
    WHEN SUBSTRING(cc.cc_zip, 1, 3) = '334' THEN 'East Coast'
    ELSE 'Other'
  END AS region_category
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
CROSS JOIN LATERAL (
  SELECT REGEXP_EXTRACT(cc.cc_name, '^([^ ]+)') AS name_first_word
) AS name_l
WHERE REGEXP_LIKE(cc.cc_name, 'Center')
  AND cp.cp_description LIKE '%Season%'
  AND cs.cs_net_profit > 0
  AND EXISTS (
    SELECT DISTINCT 1
    FROM catalog_page cp2
    WHERE cp2.cp_catalog_page_number = cp.cp_catalog_page_number
      AND cp2.cp_description LIKE '%Sale%'
  )
GROUP BY
  CONCAT(cc.cc_city, '-', cc.cc_state),
  name_l.name_first_word,
  hd.hd_buy_potential,
  cc.cc_zip,
  cc.cc_call_center_sk
ORDER BY total_profit DESC
LIMIT 100
