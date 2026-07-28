WITH ws_dd AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.web_state,
        ws.web_suite_number,
        ws.web_gmt_offset,
        ws.web_rec_end_date,
        ws.web_open_date_sk,
        ws.web_close_date_sk,
        dd.d_date,
        dd.d_year,
        CASE WHEN dd.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type
    FROM web_site ws
    JOIN date_dim dd
        ON ws.web_open_date_sk = dd.d_date_sk
    WHERE ws.web_gmt_offset = -5.00
      AND ws.web_suite_number LIKE 'Suite %'
      AND ws.web_rec_end_date >= DATE '2000-01-01'
      AND dd.d_year = 2001
)
SELECT
    web_name,
    web_state,
    day_type,
    d_date,
    d_year,
    web_gmt_offset,
    ROW_NUMBER() OVER (PARTITION BY web_state ORDER BY d_date DESC) AS state_row_num,
    RANK() OVER (ORDER BY d_date DESC) AS global_rank
FROM ws_dd
ORDER BY global_rank
LIMIT 100
