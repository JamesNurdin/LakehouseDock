WITH closed_stores AS (
    SELECT
        s.s_store_id,
        s.s_county,
        s.s_division_id,
        s.s_floor_space,
        s.s_hours,
        d.d_date,
        d.d_weekend,
        d.d_following_holiday
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_weekend = 'Y'
      AND d.d_following_holiday = 'N'
      AND regexp_like(s.s_hours, '^8AM-')
      AND s.s_county LIKE '%County'
)
SELECT
    cs.s_county,
    cs.s_division_id,
    COUNT(*) AS closed_store_cnt,
    AVG(cs.s_floor_space) AS avg_floor_space,
    REGEXP_EXTRACT(cs.s_hours, '([0-9]{1,2}[AP]M)$') AS closing_hour
FROM closed_stores cs
GROUP BY
    cs.s_county,
    cs.s_division_id,
    REGEXP_EXTRACT(cs.s_hours, '([0-9]{1,2}[AP]M)$')
ORDER BY closed_store_cnt DESC
LIMIT 20
