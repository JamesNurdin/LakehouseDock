WITH zip_stats AS (
  SELECT
    s.s_zip,
    s.s_state,
    s.s_city,
    COUNT(DISTINCT s.s_store_id) AS store_cnt,
    COUNT(DISTINCT w.w_warehouse_id) AS warehouse_cnt,
    COUNT(DISTINCT ca.ca_address_id) AS address_cnt,
    AVG(s.s_gmt_offset) AS avg_store_gmt_offset,
    AVG(w.w_gmt_offset) AS avg_warehouse_gmt_offset,
    AVG(ca.ca_gmt_offset) AS avg_address_gmt_offset
  FROM store s
  JOIN warehouse w ON s.s_zip = w.w_zip
  JOIN customer_address ca ON s.s_zip = ca.ca_zip
  WHERE s.s_rec_start_date <= CURRENT_DATE
    AND (s.s_rec_end_date IS NULL OR s.s_rec_end_date >= CURRENT_DATE)
  GROUP BY s.s_zip, s.s_state, s.s_city
)
SELECT
  s_zip,
  s_state,
  s_city,
  store_cnt,
  warehouse_cnt,
  address_cnt,
  avg_store_gmt_offset,
  avg_warehouse_gmt_offset,
  avg_address_gmt_offset,
  (avg_store_gmt_offset - avg_warehouse_gmt_offset) AS store_warehouse_gmt_diff,
  RANK() OVER (ORDER BY store_cnt DESC) AS store_cnt_rank
FROM zip_stats
WHERE store_cnt > 0
ORDER BY store_cnt_rank
LIMIT 50
