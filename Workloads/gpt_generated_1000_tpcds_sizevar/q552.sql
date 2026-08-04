WITH cp_ws_full AS (
    SELECT
        cp.cp_catalog_page_id,
        ws.web_name,
        d.d_year AS start_year,
        cp.cp_department,
        ws.web_gmt_offset
    FROM catalog_page cp
    FULL OUTER JOIN web_site ws
        ON cp.cp_start_date_sk = ws.web_open_date_sk
    LEFT JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_department IS NOT NULL OR ws.web_name IS NOT NULL
),
intersect_set AS (
    SELECT CAST(cp_ws_full.cp_catalog_page_id AS varchar) AS key_val
    FROM cp_ws_full
    WHERE cp_ws_full.start_year = 2001
    INTERSECT
    SELECT CAST(wr.wr_order_number AS varchar)
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%price%'
),
except_set AS (
    SELECT CAST(wr.wr_order_number AS varchar) AS key_val
    FROM web_returns wr
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour < 6
    EXCEPT
    SELECT CAST(wr2.wr_order_number AS varchar)
    FROM web_returns wr2
    JOIN time_dim t2
        ON wr2.wr_returned_time_sk = t2.t_time_sk
    WHERE t2.t_hour BETWEEN 12 AND 18
)
SELECT key_val,
       'INTERSECT' AS set_type
FROM intersect_set
UNION ALL
SELECT key_val,
       'EXCEPT' AS set_type
FROM except_set
ORDER BY key_val
LIMIT 100
