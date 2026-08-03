SELECT
  d.d_fy_year,
  COUNT(DISTINCT s.s_store_sk) AS closed_store_cnt,
  SUM(s.s_floor_space) AS total_floor_space
FROM
  store s
JOIN
  date_dim d
  ON s.s_closed_date_sk = d.d_date_sk
WHERE
  d.d_fy_year = 1916
  AND s.s_country = 'United States'
GROUP BY
  d.d_fy_year
