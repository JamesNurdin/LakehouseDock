WITH store_agg AS (
  SELECT
    s_state,
    s_city,
    COUNT(*) AS store_cnt,
    AVG(s_floor_space) AS avg_floor_space,
    SUM(s_tax_percentage) AS total_store_tax,
    SUM(s_number_employees) AS total_employees
  FROM store
  WHERE s_closed_date_sk IS NULL
    AND s_market_desc LIKE '%high areas%'
  GROUP BY s_state, s_city
  HAVING COUNT(*) >= 5
),
web_agg AS (
  SELECT
    web_state,
    web_city,
    COUNT(*) AS website_cnt,
    AVG(web_tax_percentage) AS avg_web_tax,
    SUM(web_gmt_offset) AS total_web_gmt_offset
  FROM web_site
  WHERE web_close_date_sk IS NULL
    AND web_tax_percentage > 5.00
  GROUP BY web_state, web_city
)
SELECT
  s.s_state,
  s.s_city,
  s.store_cnt,
  w.website_cnt,
  s.avg_floor_space,
  s.total_store_tax,
  w.avg_web_tax,
  w.total_web_gmt_offset,
  r.r_reason_desc,
  ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY s.total_store_tax DESC) AS store_rank_in_state,
  SUM(s.store_cnt) OVER (PARTITION BY s.s_state) AS total_stores_in_state
FROM store_agg s
JOIN web_agg w
  ON s.s_state = w.web_state
 AND s.s_city = w.web_city
JOIN reason r
  ON r.r_reason_desc = 'Package was damaged'
WHERE s.avg_floor_space > 2000
ORDER BY s.total_store_tax DESC, w.avg_web_tax ASC
LIMIT 100
