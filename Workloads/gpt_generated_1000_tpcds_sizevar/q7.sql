SELECT w.wp_type,
       COUNT(*) AS page_cnt,
       AVG(w.wp_char_count) AS avg_char_count
FROM web_page w
JOIN date_dim d
  ON w.wp_creation_date_sk = d.d_date_sk
WHERE d.d_date = DATE '1900-01-07'
  AND w.wp_char_count > 2000
GROUP BY w.wp_type
ORDER BY page_cnt DESC
