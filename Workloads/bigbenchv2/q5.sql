WITH logs AS (
  SELECT
    TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS wl_customer_id,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS wl_item_id,
    NULLIF(element_at(split(line, '|'), 4), '') AS wl_webpage_name
  FROM iceberg.bigbenchv2_sf1.web_logs
  WHERE element_at(split(line, '|'), 2) IS NOT NULL
    AND element_at(split(line, '|'), 3) IS NOT NULL
)
SELECT
  i.i_name,
  COUNT(*) AS cnt
FROM iceberg.bigbenchv2_sf1.web_pages w
JOIN logs l
  ON l.wl_webpage_name = w.w_web_page_name
JOIN iceberg.bigbenchv2_sf1.items i
  ON i.i_item_id = l.wl_item_id
WHERE w.w_web_page_type = 'product look up'
GROUP BY i.i_name
ORDER BY cnt DESC
LIMIT 10
