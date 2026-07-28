WITH closed_2001 AS (
   SELECT
       s.s_state,
       2001 AS closed_year,
       COUNT(*) AS closed_store_cnt,
       CASE WHEN AVG(s.s_floor_space) > 20000 THEN 'Large' ELSE 'Small' END AS size_category,
       (SELECT COUNT(*) FROM store s2 WHERE s2.s_state = s.s_state) AS total_state_store_cnt
   FROM store s
   JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND d.d_current_month = 'Y'
     AND NOT EXISTS (
         SELECT 1 FROM date_dim dh
         WHERE dh.d_date_sk = s.s_closed_date_sk
           AND dh.d_holiday = 'Y'
     )
   GROUP BY s.s_state
),
closed_2002 AS (
   SELECT
       s.s_state,
       2002 AS closed_year,
       COUNT(*) AS closed_store_cnt,
       CASE WHEN AVG(s.s_floor_space) > 15000 THEN 'Medium' ELSE 'Tiny' END AS size_category,
       (SELECT COUNT(*) FROM store s2 WHERE s2.s_state = s.s_state) AS total_state_store_cnt
   FROM store s
   JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
     AND d.d_current_month = 'N'
     AND NOT EXISTS (
         SELECT 1 FROM date_dim dh
         WHERE dh.d_date_sk = s.s_closed_date_sk
           AND dh.d_holiday = 'Y'
     )
   GROUP BY s.s_state
)
SELECT DISTINCT
    c.s_state,
    c.closed_year,
    c.closed_store_cnt,
    c.size_category,
    c.total_state_store_cnt
FROM (
    SELECT * FROM closed_2001
    UNION ALL
    SELECT * FROM closed_2002
) c
ORDER BY c.s_state, c.closed_year DESC
LIMIT 100
