WITH combined_returns AS (
  SELECT
    r.r_reason_desc AS reason_desc,
    SUBSTR(ca.ca_zip, 1, 3) AS zip_prefix,
    cr.cr_net_loss AS net_loss,
    'Catalog' AS channel
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect|broken')
    AND ca.ca_zip LIKE '9%'
  UNION ALL
  SELECT
    r.r_reason_desc AS reason_desc,
    SUBSTR(ca.ca_zip, 1, 3) AS zip_prefix,
    wr.wr_net_loss AS net_loss,
    'Web' AS channel
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect|broken')
    AND ca.ca_zip LIKE '9%'
)
SELECT
  reason_desc,
  zip_prefix,
  channel,
  SUM(net_loss) AS total_net_loss,
  MAX(CONCAT(channel, ' - ', reason_desc)) AS channel_reason,
  MAX(regexp_extract(reason_desc, '^(\\w+)', 1)) AS reason_root
FROM combined_returns
GROUP BY ROLLUP (reason_desc, zip_prefix, channel)
ORDER BY
  CASE WHEN reason_desc IS NULL THEN 1 ELSE 0 END,
  reason_desc,
  CASE WHEN zip_prefix IS NULL THEN 1 ELSE 0 END,
  zip_prefix,
  CASE WHEN channel IS NULL THEN 1 ELSE 0 END,
  channel
LIMIT 100
