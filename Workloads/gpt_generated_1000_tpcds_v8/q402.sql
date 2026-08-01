SELECT
    ws.web_name,
    ws.web_manager,
    dd.d_year,
    dd.d_month_seq,
    dd.d_day_name
FROM web_site ws
JOIN date_dim dd
  ON ws.web_open_date_sk = dd.d_date_sk
WHERE ws.web_manager = 'Jason Silva'
  AND dd.d_year = 2001
  AND dd.d_moy = 3
ORDER BY dd.d_month_seq, ws.web_name
