WITH parsed_logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 1), '') AS bigint) AS wl_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS wl_customer_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS wl_item_id,
        NULLIF(element_at(split(line, '|'), 4), '') AS wl_webpage_name,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_ts
    FROM iceberg.bigbenchv2_sf1.web_logs
    WHERE NULLIF(element_at(split(line, '|'), 2), '') IS NOT NULL
),

tagged_logs AS (
    SELECT
        wl_customer_id,
        wl_item_id,
        wl_webpage_name,
        wl_ts,
        CASE
            WHEN wl_webpage_name IN (
                'webpage#14', 'webpage#17', 'webpage#20', 'webpage#18',
                'webpage#11', 'webpage#19', 'webpage#12', 'webpage#13',
                'webpage#16'
            )
            THEN 'A'

            WHEN wl_webpage_name IN (
                'webpage#01', 'webpage#02', 'webpage#03', 'webpage#04',
                'webpage#05', 'webpage#06', 'webpage#07', 'webpage#08',
                'webpage#09', 'webpage#10'
            )
            THEN 'B'

            WHEN wl_webpage_name IN (
                'webpage#23', 'webpage#22', 'webpage#25',
                'webpage#21', 'webpage#24'
            )
            THEN 'C'

            ELSE NULL
        END AS step
    FROM parsed_logs
    WHERE wl_customer_id IS NOT NULL
      AND wl_item_id IS NOT NULL
      AND wl_ts IS NOT NULL
      AND wl_webpage_name IS NOT NULL
),

matched AS (
    SELECT *
    FROM tagged_logs
    MATCH_RECOGNIZE (
        PARTITION BY wl_customer_id
        ORDER BY wl_ts
        MEASURES
            FIRST(A.wl_item_id) AS first_view_id,
            LAST(B.wl_item_id) AS purchased_id,
            FIRST(A.wl_ts) AS first_view_ts,
            LAST(C.wl_ts) AS checkout_ts
        ONE ROW PER MATCH
        PATTERN (A+ B+ C)
        DEFINE
            A AS step = 'A',
            B AS step = 'B',
            C AS step = 'C'
    )
),

filtered AS (
    SELECT
        first_view_id,
        purchased_id,
        first_view_ts,
        checkout_ts
    FROM matched
    WHERE purchased_id BETWEEN 500 AND 550
      AND first_view_id <> purchased_id
      AND date_diff(
            'day',
            CAST(first_view_ts AS date),
            CAST(checkout_ts AS date)
          ) < 30
)

SELECT
    i1.i_name AS viewed_item_name,
    i2.i_name AS purchased_item_name,
    COUNT(*) AS cnt
FROM filtered f
JOIN iceberg.bigbenchv2_sf1.items i1
  ON i1.i_item_id = f.first_view_id
JOIN iceberg.bigbenchv2_sf1.items i2
  ON i2.i_item_id = f.purchased_id
GROUP BY
    i1.i_name,
    i2.i_name
ORDER BY
    cnt DESC,
    i1.i_name
LIMIT 5