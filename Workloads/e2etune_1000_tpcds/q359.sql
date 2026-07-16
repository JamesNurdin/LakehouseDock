WITH active_store AS (
  SELECT
    s_market_id,
    s_market_desc,
    s_state,
    s_gmt_offset,
    s_floor_space,
    s_tax_percentage,
    s_store_id
  FROM store
  WHERE s_rec_start_date <= current_date
    AND (s_rec_end_date IS NULL OR s_rec_end_date >= current_date)
),
active_web AS (
  SELECT
    web_mkt_id,
    web_mkt_desc,
    web_state,
    web_gmt_offset,
    web_tax_percentage,
    web_site_id
  FROM web_site
  WHERE web_rec_start_date <= current_date
    AND (web_rec_end_date IS NULL OR web_rec_end_date >= current_date)
)
SELECT
  s.s_market_id,
  s.s_market_desc,
  COUNT(DISTINCT s.s_store_id) AS store_count,
  SUM(s.s_floor_space) AS total_floor_space,
  AVG(s.s_tax_percentage) AS avg_store_tax,
  COUNT(DISTINCT w.web_site_id) AS website_count,
  AVG(w.web_tax_percentage) AS avg_website_tax,
  ROUND(SUM(s.s_floor_space) / NULLIF(COUNT(DISTINCT s.s_store_id), 0), 2) AS avg_floor_space_per_store,
  RANK() OVER (ORDER BY SUM(s.s_floor_space) DESC) AS floor_space_rank
FROM active_store s
JOIN active_web w
  ON s.s_market_id = w.web_mkt_id
WHERE s.s_state = w.web_state
  AND s.s_gmt_offset BETWEEN -5 AND 5
  AND w.web_gmt_offset BETWEEN -5 AND 5
GROUP BY s.s_market_id, s.s_market_desc
ORDER BY total_floor_space DESC
LIMIT 10
