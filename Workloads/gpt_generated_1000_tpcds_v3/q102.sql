WITH cc_returns_gmt_minus8 AS (
  SELECT
    cc.cc_call_center_id AS call_center_id,
    cc.cc_name AS call_center_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(cr.cr_net_loss) AS total_net_loss,
    'GMT_-8' AS gmt_category
  FROM tpcds.call_center cc
  JOIN tpcds.catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_gmt_offset = -8.00
    AND cc.cc_hours = '8AM-12AM'
    AND cr.cr_return_amount > 1000
  GROUP BY cc.cc_call_center_id, cc.cc_name
),
cc_returns_gmt_minus5 AS (
  SELECT
    cc.cc_call_center_id AS call_center_id,
    cc.cc_name AS call_center_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(cr.cr_net_loss) AS total_net_loss,
    'GMT_-5' AS gmt_category
  FROM tpcds.call_center cc
  JOIN tpcds.catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_gmt_offset = -5.00
    AND cc.cc_hours = '8AM-4PM'
    AND cr.cr_return_tax > 50
  GROUP BY cc.cc_call_center_id, cc.cc_name
)
SELECT
  call_center_id,
  call_center_name,
  total_return_amount,
  total_store_credit,
  total_net_loss,
  gmt_category
FROM (
  SELECT
    call_center_id,
    call_center_name,
    total_return_amount,
    total_store_credit,
    total_net_loss,
    gmt_category
  FROM cc_returns_gmt_minus8
  UNION ALL
  SELECT
    call_center_id,
    call_center_name,
    total_return_amount,
    total_store_credit,
    total_net_loss,
    gmt_category
  FROM cc_returns_gmt_minus5
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
