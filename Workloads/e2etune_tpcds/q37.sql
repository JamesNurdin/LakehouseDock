WITH site_openings AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        ws.web_open_date_sk,
        ws.web_state,
        ws.web_country,
        ws.web_tax_percentage,
        ws.web_gmt_offset,
        td.t_hour,
        td.t_shift,
        td.t_sub_shift,
        td.t_am_pm,
        ws.web_rec_start_date,
        ws.web_rec_end_date
    FROM web_site ws
    JOIN time_dim td
        ON td.t_time_sk = ws.web_open_date_sk
    WHERE td.t_shift = 'first'
      AND td.t_sub_shift = 'morning'
      AND ws.web_rec_start_date >= DATE '2020-01-01'
      AND ws.web_rec_start_date < DATE '2021-01-01'
)
SELECT
    t_hour,
    t_shift,
    t_sub_shift,
    web_state,
    COUNT(DISTINCT web_site_sk) AS site_count,
    AVG(web_tax_percentage) AS avg_tax_pct,
    SUM(web_gmt_offset) AS total_gmt_offset,
    MIN(web_rec_start_date) AS earliest_start,
    MAX(web_rec_end_date) AS latest_end
FROM site_openings
WHERE t_am_pm = 'AM'
  AND web_country = 'United States'
GROUP BY t_hour, t_shift, t_sub_shift, web_state
HAVING COUNT(DISTINCT web_site_sk) > 5
ORDER BY site_count DESC
LIMIT 100
