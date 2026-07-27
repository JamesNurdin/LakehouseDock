/*
Goal: Identify states with stores that closed in fiscal quarter 20 whose street names are capitalized and contain the letter 'e',
join them to call centers opened in the same quarter whose manager name starts with 'J', and optionally link to web sites opened in that quarter whose name includes the word "Online". The query extracts the manager's first name, builds a location string, flags web presence, aggregates store counts and floor space, and orders the result.
*/
WITH store_q AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_city,
        s.s_floor_space,
        d.d_fy_quarter_seq
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq = 20
      AND regexp_like(s.s_street_name, '^[A-Z][a-z]+$')
      AND s.s_street_name LIKE '%e%'
),
cc_q AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_manager,
        cc.cc_sq_ft,
        d.d_fy_quarter_seq
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq = 20
      AND regexp_like(cc.cc_manager, '^J')
),
web_q AS (
    SELECT
        w.web_site_sk,
        w.web_name,
        w.web_mkt_id,
        d.d_fy_quarter_seq
    FROM web_site w
    JOIN date_dim d
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq = 20
      AND regexp_like(w.web_name, 'Online')
)
SELECT
    st.s_state,
    COUNT(DISTINCT st.s_store_sk) AS store_cnt,
    AVG(st.s_floor_space) AS avg_floor_space,
    SUM(cc.cc_sq_ft) AS total_cc_sq_ft,
    regexp_extract(cc.cc_manager, '^([A-Za-z]+)', 1) AS manager_first_name,
    CASE WHEN w.web_mkt_id IS NULL THEN 'NoWeb' ELSE 'HasWeb' END AS web_presence,
    concat(st.s_city, ', ', st.s_state) AS location
FROM store_q st
JOIN cc_q cc
    ON st.d_fy_quarter_seq = cc.d_fy_quarter_seq
LEFT JOIN web_q w
    ON st.d_fy_quarter_seq = w.d_fy_quarter_seq
WHERE substring(st.s_city, 1, 1) = 'A'
GROUP BY st.s_state, st.s_city, cc.cc_manager, w.web_mkt_id
ORDER BY store_cnt DESC, st.s_state
LIMIT 100
