SELECT
    s.s_county,
    COUNT(*) AS closed_store_cnt
FROM store AS s
JOIN date_dim AS d
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_fy_year = 1918
  AND s.s_state = 'MI'
GROUP BY s.s_county
ORDER BY closed_store_cnt DESC
