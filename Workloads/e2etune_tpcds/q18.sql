WITH band_stats AS (
  SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(wp.wp_web_page_sk) AS page_cnt,
    AVG(wp.wp_char_count) AS avg_char_cnt,
    SUM(wp.wp_link_count) AS total_link_cnt,
    MAX(wp.wp_image_count) AS max_image_cnt
  FROM income_band ib
  JOIN web_page wp
    ON wp.wp_char_count BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
  WHERE wp.wp_rec_end_date >= DATE '1999-01-01'
    AND wp.wp_rec_end_date < DATE '2002-01-01'
    AND wp.wp_autogen_flag = 'N'
  GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  page_cnt,
  avg_char_cnt,
  total_link_cnt,
  max_image_cnt,
  RANK() OVER (ORDER BY page_cnt DESC) AS page_cnt_rank
FROM band_stats
WHERE page_cnt > 0
ORDER BY page_cnt_rank
LIMIT 5
