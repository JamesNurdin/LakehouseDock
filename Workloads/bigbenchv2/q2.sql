WITH parsed_logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS uid,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS item,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS event_ts
    FROM iceberg.bigbenchv2_sf1.web_logs
    WHERE NULLIF(element_at(split(line, '|'), 2), '') IS NOT NULL
      AND NULLIF(element_at(split(line, '|'), 3), '') IS NOT NULL
      AND NULLIF(element_at(split(line, '|'), 5), '') IS NOT NULL
),

session_flags AS (
    SELECT
        uid,
        item,
        event_ts,
        to_unixtime(event_ts) AS event_time_s,
        CASE
            WHEN (
                to_unixtime(event_ts)
                - lag(to_unixtime(event_ts)) OVER (
                    PARTITION BY uid
                    ORDER BY event_ts
                )
            ) >= 600
            THEN 1
            ELSE 0
        END AS new_session
    FROM parsed_logs
    WHERE uid IS NOT NULL
      AND item IS NOT NULL
      AND event_ts IS NOT NULL
),

sessionized AS (
    SELECT
        concat(
            CAST(uid AS varchar),
            '_',
            CAST(
                sum(new_session) OVER (
                    PARTITION BY uid
                    ORDER BY event_time_s
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) AS varchar
            )
        ) AS session_id,
        item
    FROM session_flags
),

distinct_session_items AS (
    SELECT DISTINCT
        session_id,
        item
    FROM sessionized
),

session_item_arrays AS (
    SELECT
        session_id,
        array_agg(item) AS item_array
    FROM distinct_session_items
    GROUP BY session_id
),

sessions_with_seed AS (
    SELECT
        session_id,
        item_array
    FROM session_item_arrays
    WHERE contains(item_array, CAST(500 AS bigint))
),

co_occurring_items AS (
    SELECT
        unnested_item AS item_id_1
    FROM sessions_with_seed
    CROSS JOIN UNNEST(item_array) AS t(unnested_item)
    WHERE unnested_item <> CAST(500 AS bigint)
)

SELECT
    item_id_1,
    CAST(500 AS bigint) AS item_id_2,
    COUNT(*) AS cnt
FROM co_occurring_items
GROUP BY item_id_1
ORDER BY
    cnt DESC,
    item_id_1
LIMIT 10