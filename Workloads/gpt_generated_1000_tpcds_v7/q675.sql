WITH catalog AS (
  SELECT
    ca.ca_state,
    d.d_year,
    cr.cr_net_loss,
    ca.ca_suite_number,
    ca.ca_address_id
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE regexp_like(ca.ca_address_id, '^A{8}')
    AND ca.ca_street_number LIKE '3%'
    AND regexp_like(ca.ca_suite_number, '\\d')
),
web AS (
  SELECT
    ca.ca_state,
    d.d_year,
    wr.wr_net_loss,
    ca.ca_suite_number,
    ca.ca_address_id
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE regexp_like(ca.ca_address_id, '^A{8}')
    AND ca.ca_street_number LIKE '3%'
    AND regexp_like(ca.ca_suite_number, '\\d')
),
store_closure AS (
  SELECT
    d.d_year,
    COUNT(DISTINCT s.s_store_id) AS closed_stores
  FROM store s
  JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  GROUP BY d.d_year
)
SELECT
  combined.ca_state,
  combined.d_year,
  SUM(COALESCE(combined.cr_net_loss, 0) + COALESCE(combined.wr_net_loss, 0)) AS total_net_loss,
  COUNT(*) FILTER (WHERE combined.cr_net_loss IS NOT NULL) AS catalog_return_count,
  COUNT(*) FILTER (WHERE combined.wr_net_loss IS NOT NULL) AS web_return_count,
  CONCAT(combined.ca_state, '-', CAST(combined.d_year AS VARCHAR)) AS state_year_key,
  REGEXP_EXTRACT(MIN(combined.ca_suite_number), '(\\d+)') AS sample_suite_digits,
  SUBSTRING(MIN(combined.ca_address_id), 1, 5) AS address_id_prefix,
  sc.closed_stores
FROM (
  SELECT ca_state, d_year, cr_net_loss, NULL AS wr_net_loss, ca_suite_number, ca_address_id FROM catalog
  UNION ALL
  SELECT ca_state, d_year, NULL AS cr_net_loss, wr_net_loss, ca_suite_number, ca_address_id FROM web
) AS combined
LEFT JOIN store_closure sc ON combined.d_year = sc.d_year
GROUP BY combined.ca_state, combined.d_year, sc.closed_stores
ORDER BY total_net_loss DESC
LIMIT 10
