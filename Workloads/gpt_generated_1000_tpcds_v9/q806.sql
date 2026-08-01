SELECT
  i.i_category,
  ca.ca_county,
  SUM(sr.sr_return_amt) AS total_return_amount,
  COUNT(*) AS return_count,
  AVG(sr.sr_return_amt) AS avg_return_amount,
  MIN(sr.sr_return_amt) AS min_return_amount,
  MAX(sr.sr_return_amt) AS max_return_amount
FROM tpcds.store_returns sr
INNER JOIN tpcds.item i
  ON sr.sr_item_sk = i.i_item_sk
INNER JOIN tpcds.customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE i.i_category_id = 5
  AND ca.ca_county = 'York County'
  AND i.i_rec_end_date >= DATE '2000-01-01'
  AND EXISTS (
    SELECT 1
    FROM tpcds.household_demographics hd
    WHERE hd.hd_demo_sk = sr.sr_hdemo_sk
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_dep_count <= 5
  )
GROUP BY i.i_category, ca.ca_county
HAVING SUM(sr.sr_return_amt) > 1000

UNION

SELECT
  i.i_category,
  ca.ca_county,
  SUM(sr.sr_return_amt) AS total_return_amount,
  COUNT(*) AS return_count,
  AVG(sr.sr_return_amt) AS avg_return_amount,
  MIN(sr.sr_return_amt) AS min_return_amount,
  MAX(sr.sr_return_amt) AS max_return_amount
FROM tpcds.store_returns sr
INNER JOIN tpcds.item i
  ON sr.sr_item_sk = i.i_item_sk
INNER JOIN tpcds.customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE i.i_category_id = 6
  AND ca.ca_county = 'Richland County'
  AND i.i_rec_end_date <= DATE '2001-01-01'
  AND EXISTS (
    SELECT 1
    FROM tpcds.household_demographics hd
    WHERE hd.hd_demo_sk = sr.sr_hdemo_sk
      AND hd.hd_vehicle_count = 0
  )
GROUP BY i.i_category, ca.ca_county
HAVING SUM(sr.sr_return_amt) > 500

ORDER BY total_return_amount DESC
LIMIT 100
