WITH catalog_data AS (
  SELECT
    'catalog' AS return_source,
    cr.cr_returned_date_sk AS return_date_sk,
    cr.cr_return_amt_inc_tax AS return_amount,
    r.r_reason_desc AS reason_desc,
    ca.ca_county AS county
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
  WHERE cr.cr_return_amt_inc_tax > 10
    AND cr.cr_return_amt_inc_tax < 200
),
web_data AS (
  SELECT
    'web' AS return_source,
    wr.wr_returned_date_sk AS return_date_sk,
    wr.wr_return_amt_inc_tax AS return_amount,
    r.r_reason_desc AS reason_desc,
    ca.ca_county AS county
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
  WHERE wr.wr_return_amt_inc_tax > 10
    AND wr.wr_return_amt_inc_tax < 200
)
SELECT
  return_source,
  return_date_sk,
  return_amount,
  reason_desc,
  county,
  ROW_NUMBER() OVER (PARTITION BY reason_desc ORDER BY return_amount DESC) AS rn
FROM (
  SELECT * FROM catalog_data
  UNION ALL
  SELECT * FROM web_data
) combined
ORDER BY return_amount DESC
LIMIT 100
