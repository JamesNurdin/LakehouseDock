WITH open_sites AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        ws.web_name,
        d.d_year,
        CASE WHEN ws.web_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region,
        (SELECT COUNT(*) FROM date_dim d2 WHERE d2.d_year = d.d_year) AS dates_in_same_year,
        sv.state_val
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    /* expand an array built from the site state and a constant */
    CROSS JOIN UNNEST(ARRAY[ws.web_state, 'NY']) AS sv(state_val)
    /* small computed set for a cross join */
    CROSS JOIN (SELECT 'A' AS grp UNION ALL SELECT 'B' AS grp) AS g
    WHERE ws.web_rec_start_date >= DATE '1999-01-01'
      AND ws.web_state IN (SELECT DISTINCT web_state FROM web_site WHERE web_manager IS NOT NULL)
      AND EXISTS (SELECT 1 FROM date_dim dd WHERE dd.d_date = ws.web_rec_start_date)
),

close_sites AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        ws.web_name,
        d.d_year,
        CASE WHEN ws.web_gmt_offset > 0 THEN 'East' ELSE 'West' END AS region,
        (SELECT COUNT(*) FROM date_dim d2 WHERE d2.d_year = d.d_year) AS dates_in_same_year,
        sv.state_val
    FROM web_site ws
    JOIN date_dim d ON ws.web_close_date_sk = d.d_date_sk
    CROSS JOIN UNNEST(ARRAY[ws.web_state, 'CA']) AS sv(state_val)
    CROSS JOIN (SELECT 'A' AS grp UNION ALL SELECT 'B' AS grp) AS g
    WHERE ws.web_rec_end_date >= DATE '1999-01-01'
      AND ws.web_state IN (SELECT DISTINCT web_state FROM web_site WHERE web_manager IS NOT NULL)
      AND EXISTS (SELECT 1 FROM date_dim dd WHERE dd.d_date = ws.web_rec_end_date)
)

/* combine openings and closings, then remove a specific key set */
SELECT
    os.web_site_sk,
    os.web_site_id,
    os.web_name,
    os.d_year,
    os.region,
    os.dates_in_same_year,
    os.state_val
FROM (
    SELECT * FROM open_sites
    UNION ALL
    SELECT * FROM close_sites
) AS os
EXCEPT
SELECT
    ws.web_site_sk,
    ws.web_site_id,
    ws.web_name,
    d.d_year,
    CASE WHEN ws.web_gmt_offset > 0 THEN 'East' ELSE 'West' END,
    (SELECT COUNT(*) FROM date_dim d2 WHERE d2.d_year = d.d_year),
    NULL
FROM web_site ws
JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
WHERE ws.web_state = 'TX'
ORDER BY web_site_id
OFFSET 10
LIMIT 100
