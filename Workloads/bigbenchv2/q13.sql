WITH logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS uid,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS item_id,
        CAST(to_unixtime(TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp)) AS bigint) AS tstamp
    FROM iceberg.bigbenchv2_sf1.web_logs
    WHERE NULLIF(element_at(split(line, '|'), 2), '') IS NOT NULL
      AND NULLIF(element_at(split(line, '|'), 3), '') IS NOT NULL
      AND NULLIF(element_at(split(line, '|'), 5), '') IS NOT NULL
),

session_flags AS (
    SELECT
        uid,
        tstamp,
        CASE
            WHEN (
                tstamp - lag(tstamp) OVER (
                    PARTITION BY uid
                    ORDER BY tstamp
                )
            ) >= 600
            THEN 1
            ELSE 0
        END AS new_session
    FROM logs
),

session_numbers AS (
    SELECT
        uid,
        tstamp,
        SUM(new_session) OVER (
            PARTITION BY uid
            ORDER BY tstamp
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_num
    FROM session_flags
),

sessions AS (
    SELECT
        uid,
        session_num,
        MIN(tstamp) AS start_time,
        MAX(tstamp) AS end_time
    FROM session_numbers
    GROUP BY
        uid,
        session_num
)

SELECT
    AVG(end_time - start_time) AS avg_session_seconds
FROM sessions