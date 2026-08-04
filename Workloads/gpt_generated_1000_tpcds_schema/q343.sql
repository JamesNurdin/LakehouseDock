WITH
  catalog_loss AS (
    SELECT
      cr.cr_order_number AS order_number,
      cr.cr_net_loss AS net_loss,
      r.r_reason_desc,
      SUBSTRING(r.r_reason_desc FROM 1 FOR 10) AS reason_prefix,
      d.d_year,
      CONCAT(cc.cc_name, ' - ', cc.cc_city) AS call_center_info
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)did not')
      AND cc.cc_state LIKE 'C%'
      AND d.d_year = 2001
  ),
  web_loss AS (
    SELECT
      wr.wr_order_number AS order_number,
      wr.wr_net_loss AS net_loss,
      r.r_reason_desc,
      SUBSTRING(r.r_reason_desc FROM 1 FOR 10) AS reason_prefix,
      d.d_year,
      CONCAT(CAST(wr.wr_returning_customer_sk AS varchar), '_', CAST(wr.wr_returned_date_sk AS varchar)) AS return_key
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)did not')
      AND d.d_year = 2001
  )
SELECT
  'Both' AS source,
  cl.order_number,
  cl.net_loss AS catalog_net_loss,
  wl.net_loss AS web_net_loss,
  cl.reason_prefix,
  cl.call_center_info
FROM (
  SELECT order_number FROM catalog_loss
  INTERSECT
  SELECT order_number FROM web_loss
) common_orders
JOIN catalog_loss cl ON cl.order_number = common_orders.order_number
LEFT JOIN web_loss wl ON wl.order_number = common_orders.order_number
UNION ALL
SELECT
  'CatalogOnly' AS source,
  cl.order_number,
  cl.net_loss AS catalog_net_loss,
  NULL AS web_net_loss,
  cl.reason_prefix,
  cl.call_center_info
FROM (
  SELECT order_number FROM catalog_loss
  EXCEPT
  SELECT order_number FROM web_loss
) catalog_only
JOIN catalog_loss cl ON cl.order_number = catalog_only.order_number
ORDER BY source, order_number
LIMIT 100
