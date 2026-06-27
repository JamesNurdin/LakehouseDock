WITH parsed_logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS uid,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS item,
        NULLIF(element_at(split(line, '|'), 4), '') AS webpage_name,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS event_ts
    FROM iceberg.bigbenchv2_sf1.web_logs
    WHERE NULLIF(element_at(split(line, '|'), 2), '') IS NOT NULL
      AND NULLIF(element_at(split(line, '|'), 3), '') IS NOT NULL
      AND NULLIF(element_at(split(line, '|'), 4), '') IS NOT NULL
      AND NULLIF(element_at(split(line, '|'), 5), '') IS NOT NULL
),

logs_with_page_type AS (
    SELECT
        l.uid,
        l.item,
        w.w_web_page_type AS wptype,
        l.event_ts,
        to_unixtime(l.event_ts) AS tstamp
    FROM parsed_logs l
    JOIN iceberg.bigbenchv2_sf1.web_pages w
      ON l.webpage_name = w.w_web_page_name
    WHERE l.uid IS NOT NULL
      AND l.item IS NOT NULL
      AND l.event_ts IS NOT NULL
),

session_flags AS (
    SELECT
        uid,
        item,
        wptype,
        event_ts,
        tstamp,
        CASE
            WHEN (
                tstamp
                - lag(tstamp) OVER (
                    PARTITION BY uid
                    ORDER BY event_ts
                )
            ) >= 600
            THEN 1
            ELSE 0
        END AS new_session
    FROM logs_with_page_type
),

sessionized AS (
    SELECT
        uid,
        item,
        wptype,
        tstamp,
        concat(
            CAST(uid AS varchar),
            '_',
            CAST(
                sum(new_session) OVER (
                    PARTITION BY uid
                    ORDER BY tstamp
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) AS varchar
            )
        ) AS session_id
    FROM session_flags
),

session_add_to_cart AS (
    SELECT
        uid,
        session_id,
        min(tstamp) AS first_add_to_cart_tstamp
    FROM sessionized
    WHERE wptype = 'add to cart'
    GROUP BY
        uid,
        session_id
),

session_checkout_after_cart AS (
    SELECT DISTINCT
        s.uid,
        s.session_id
    FROM sessionized s
    JOIN session_add_to_cart a
      ON s.uid = a.uid
     AND s.session_id = a.session_id
    WHERE s.wptype = 'checkout'
      AND s.tstamp > a.first_add_to_cart_tstamp
),

abandoned_sessions AS (
    SELECT
        s.uid,
        s.session_id,
        min(s.tstamp) AS start_s,
        max(s.tstamp) AS end_s,
        count(*) AS pages
    FROM sessionized s
    JOIN session_add_to_cart a
      ON s.uid = a.uid
     AND s.session_id = a.session_id
    LEFT JOIN session_checkout_after_cart c
      ON s.uid = c.uid
     AND s.session_id = c.session_id
    WHERE c.session_id IS NULL
    GROUP BY
        s.uid,
        s.session_id
)

SELECT
    c.c_customer_id,
    c.c_name,
    avg(a.pages) AS s_pages
FROM abandoned_sessions a
JOIN iceberg.bigbenchv2_sf1.customers c
  ON a.uid = c.c_customer_id
GROUP BY
    c.c_customer_id,
    c.c_name
ORDER BY
    s_pages DESC,
    c.c_customer_id
LIMIT 50