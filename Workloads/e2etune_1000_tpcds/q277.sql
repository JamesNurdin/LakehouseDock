WITH agg AS (
  SELECT
    w.w_state,
    COUNT(DISTINCT w.w_warehouse_id) AS warehouse_cnt,
    AVG(w.w_warehouse_sq_ft) AS avg_sq_ft,
    r.r_reason_desc,
    COUNT(*) AS pair_cnt,
    SUM(wp.wp_char_count) AS total_char_count,
    AVG(wp.wp_image_count) AS avg_image_count
  FROM warehouse w
  JOIN reason r
    ON (w.w_warehouse_sk % 5) = (r.r_reason_sk % 5)
  JOIN web_page wp
    ON (wp.wp_web_page_sk % 7) = (w.w_warehouse_sk % 7)
  WHERE w.w_gmt_offset >= -6.00
    AND r.r_reason_desc LIKE '%product%'
    AND wp.wp_char_count > 1000
  GROUP BY w.w_state, r.r_reason_desc
  HAVING COUNT(*) > 10
)
SELECT
  a.w_state,
  a.warehouse_cnt,
  a.avg_sq_ft,
  a.r_reason_desc,
  a.pair_cnt,
  a.total_char_count,
  a.avg_image_count,
  ROW_NUMBER() OVER (PARTITION BY a.w_state ORDER BY a.avg_sq_ft DESC) AS rn_state,
  RANK() OVER (ORDER BY a.pair_cnt DESC) AS pair_rnk
FROM agg a
ORDER BY rn_state, pair_rnk DESC
LIMIT 100
