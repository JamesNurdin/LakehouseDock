/*
  Goal: Summarize net profit performance by calendar year and call‑center state, only for catalog pages whose type starts with 'monthly' and whose description mentions the word "discount". The query extracts any numeric sequence from the call‑center name using a regular expression (via a LATERAL subquery), classifies profits as positive or negative with a CASE expression, and aggregates the results.
*/
SELECT
  d.d_year,
  cc.cc_state,
  l.extracted_num AS cc_name_number,
  CASE
    WHEN cs.cs_net_profit > 0 THEN 'POS'
    ELSE 'NEG'
  END AS profit_flag,
  COUNT(*) AS order_cnt,
  SUM(cs.cs_net_profit) AS total_net_profit
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
CROSS JOIN LATERAL (
  SELECT regexp_extract(cc.cc_name, '(\\d+)', 1) AS extracted_num
) AS l
WHERE cp.cp_type LIKE 'monthly%'
  AND regexp_like(cp.cp_description, '(?i)discount')
  AND cc.cc_tax_percentage > 0.05
GROUP BY
  d.d_year,
  cc.cc_state,
  l.extracted_num,
  CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END
ORDER BY total_net_profit DESC, d.d_year ASC
LIMIT 100
