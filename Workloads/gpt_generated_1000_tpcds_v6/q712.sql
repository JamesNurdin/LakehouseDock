WITH max_date_2000 AS (
       SELECT MAX(d_date) AS max_dt
       FROM date_dim
       WHERE d_year = 2000
   ),
   store_dates AS (
       SELECT
           s.s_store_sk,
           s.s_store_name,
           s.s_number_employees,
           s.s_state,
           s.s_closed_date_sk,
           d.d_date AS closed_date,
           d.d_year AS closed_year,
           d.d_month_seq,
           d.d_day_name
       FROM store s
       JOIN date_dim d
         ON s.s_closed_date_sk = d.d_date_sk
       WHERE d.d_year BETWEEN 1999 AND 2001
         AND s.s_state = 'CA'
         AND s.s_street_type = 'Way'
   )
SELECT
    sd.s_store_name,
    sd.closed_date,
    COALESCE(ws.web_name, 'No Site') AS web_name,
    ws.web_zip,
    CASE
        WHEN sd.s_number_employees > 200 THEN 'Large'
        WHEN sd.s_number_employees BETWEEN 100 AND 200 THEN 'Medium'
        ELSE 'Small'
    END AS store_size_category,
    RANK() OVER (PARTITION BY sd.s_state ORDER BY sd.s_number_employees DESC) AS emp_rank_state,
    (SELECT max_dt FROM max_date_2000) AS max_date_2000
FROM store_dates sd
LEFT JOIN web_site ws
  ON sd.s_closed_date_sk = ws.web_open_date_sk
WHERE ws.web_zip = '86787' OR ws.web_zip IS NULL
ORDER BY emp_rank_state, sd.s_store_name
LIMIT 100
