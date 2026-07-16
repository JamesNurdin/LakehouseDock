SELECT
  cp.cp_type,
  ws.web_state,
  COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_page_cnt,
  AVG(cp.cp_catalog_page_number) AS avg_page_number,
  COUNT(DISTINCT sm.sm_ship_mode_sk) AS distinct_ship_modes,
  SUM(ws.web_tax_percentage) AS total_tax_pct,
  RANK() OVER (ORDER BY SUM(ws.web_tax_percentage) DESC) AS tax_rank
FROM
  catalog_page cp
  JOIN ship_mode sm ON cp.cp_type = sm.sm_type
  JOIN web_site ws ON cp.cp_catalog_number = ws.web_mkt_id
WHERE
  cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
  AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451200
  AND ws.web_gmt_offset BETWEEN -5.00 AND 5.00
GROUP BY
  cp.cp_type,
  ws.web_state
HAVING
  COUNT(DISTINCT cp.cp_catalog_page_sk) > 5
ORDER BY
  total_tax_pct DESC,
  cp.cp_type
