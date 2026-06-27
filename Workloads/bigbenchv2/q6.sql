WITH logs AS (
  SELECT
    TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) AS wl_customer_id,
    TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint) AS wl_item_id,
    NULLIF(element_at(split(line, '|'), 4), '') AS wl_webpage_name
  FROM iceberg.bigbenchv2_sf1.web_logs
  WHERE element_at(split(line, '|'), 2) IS NOT NULL
    AND element_at(split(line, '|'), 3) IS NOT NULL
),

browsed AS (
  SELECT
    l.wl_item_id AS br_id,
    COUNT(*) AS br_count
  FROM iceberg.bigbenchv2_sf1.web_pages wp
  JOIN logs l ON l.wl_webpage_name = wp.w_web_page_name
  WHERE wp.w_web_page_type = 'product look up'
  GROUP BY l.wl_item_id
),

purchased AS (
  SELECT
    l.wl_item_id AS pu_id,
    COUNT(*) AS pu_count
  FROM iceberg.bigbenchv2_sf1.web_pages wp
  JOIN logs l ON l.wl_webpage_name = wp.w_web_page_name
  WHERE wp.w_web_page_type = 'add to cart'
  GROUP BY l.wl_item_id
)
SELECT
  i.i_item_id,
  (b.br_count - p.pu_count) AS cnt
FROM browsed b
JOIN purchased p ON b.br_id = p.pu_id
JOIN iceberg.bigbenchv2_sf1.items i ON b.br_id = i.i_item_id
ORDER BY cnt DESC
LIMIT 5
