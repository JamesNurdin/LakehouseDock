WITH logs AS (
  SELECT
    TRY_CAST(NULLIF(element_at(split(line, '|'), 1), '') AS bigint) AS wl_id,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS wl_customer_id,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS wl_item_id,
    NULLIF(element_at(split(line, '|'), 4), '') AS wl_webpage_name,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_timestamp
  FROM iceberg.bigbenchv2_sf1.web_logs
),

enriched_logs AS (
  SELECT
    l.wl_customer_id AS uid,
    l.wl_item_id AS item,
    w.w_web_page_type AS wptype,
    to_unixtime(l.wl_timestamp) AS tstamp
  FROM logs l
  JOIN iceberg.bigbenchv2_sf1.web_pages w
    ON l.wl_webpage_name = w.w_web_page_name
  WHERE l.wl_customer_id IS NOT NULL
    AND l.wl_item_id IS NOT NULL
    AND l.wl_timestamp IS NOT NULL
),

sessionize AS (
  SELECT
    uid,
    item,
    wptype,
    tstamp,
    CASE
      WHEN (
        tstamp - LAG(tstamp) OVER (
          PARTITION BY uid
          ORDER BY tstamp
        )
      ) >= 600
      THEN 1
      ELSE 0
    END AS new_session
  FROM enriched_logs
),

sessions AS (
  SELECT
    uid,
    item,
    wptype,
    tstamp,
    CONCAT(
      CAST(uid AS varchar),
      '_',
      CAST(
        SUM(new_session) OVER (
          PARTITION BY uid
          ORDER BY tstamp
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS varchar
      )
    ) AS session_id
  FROM sessionize
)

SELECT
  c.c_customer_id,
  c.c_name,
  COUNT(*) AS cnt_se
FROM sessions s
JOIN iceberg.bigbenchv2_sf1.customers c
  ON c.c_customer_id = s.uid
GROUP BY
  c.c_customer_id,
  c.c_name
HAVING COUNT(*) > 10
ORDER BY cnt_se DESC
LIMIT 50