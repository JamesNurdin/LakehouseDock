WITH sampled_returns AS (
  SELECT *
  FROM store_returns TABLESAMPLE BERNOULLI (10)
)
SELECT
  COALESCE(ca.ca_city, 'No City') AS city,
  COALESCE(ca.ca_state, 'No State') AS state,
  CONCAT(COALESCE(ca.ca_city, 'No City'), ', ', COALESCE(ca.ca_state, 'No State')) AS city_state,
  SUBSTRING(COALESCE(ca.ca_zip, '' ) FROM 1 FOR 3) AS zip_prefix,
  REGEXP_EXTRACT(COALESCE(ca.ca_street_name, ''), '^([A-Za-z]+)', 1) AS street_name_first_word,
  COUNT(sr.sr_ticket_number) AS return_count,
  SUM(sr.sr_net_loss) AS total_net_loss,
  AVG(sr.sr_return_amt) AS avg_return_amount,
  SUM(sr.sr_net_loss) - (SELECT avg(sr_net_loss) FROM store_returns) AS net_loss_vs_avg
FROM sampled_returns sr
FULL OUTER JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE
  (ca.ca_city IS NULL OR ca.ca_city LIKE '%town%' OR ca.ca_city LIKE '%ville%')
  AND (ca.ca_street_name IS NULL OR regexp_like(ca.ca_street_name, '^[A-Za-z]+\\s+[A-Za-z]+$'))
GROUP BY
  COALESCE(ca.ca_city, 'No City'),
  COALESCE(ca.ca_state, 'No State'),
  CONCAT(COALESCE(ca.ca_city, 'No City'), ', ', COALESCE(ca.ca_state, 'No State')),
  SUBSTRING(COALESCE(ca.ca_zip, '' ) FROM 1 FOR 3),
  REGEXP_EXTRACT(COALESCE(ca.ca_street_name, ''), '^([A-Za-z]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
