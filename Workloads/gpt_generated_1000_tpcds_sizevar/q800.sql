WITH sampled_returns AS (
  SELECT
    sr_returned_date_sk,
    sr_return_time_sk,
    sr_item_sk,
    sr_customer_sk,
    sr_cdemo_sk,
    sr_hdemo_sk,
    sr_addr_sk,
    sr_store_sk,
    sr_reason_sk,
    sr_ticket_number,
    sr_return_quantity,
    sr_return_amt,
    sr_return_tax,
    sr_return_amt_inc_tax,
    sr_fee,
    sr_return_ship_cost,
    sr_refunded_cash,
    sr_reversed_charge,
    sr_store_credit,
    sr_net_loss
  FROM store_returns
  TABLESAMPLE BERNOULLI (10)
),
aggregated_demo AS (
  SELECT cd_demo_sk,
         COUNT(*) AS demo_cnt,
         AVG(cd_dep_employed_count) AS avg_dep_employed
  FROM customer_demographics
  WHERE cd_education_status LIKE '%Degree%'
  GROUP BY cd_demo_sk
),
full_demo AS (
  SELECT
    sr.sr_cdemo_sk,
    sr.sr_return_amt,
    sr.sr_fee,
    sr.sr_customer_sk,
    sr.sr_addr_sk,
    ad.demo_cnt,
    ad.avg_dep_employed
  FROM sampled_returns sr
  FULL OUTER JOIN aggregated_demo ad
    ON sr.sr_cdemo_sk = ad.cd_demo_sk
),
joined_all AS (
  SELECT
    fd.*,
    ca.ca_city,
    ca.ca_state,
    ca.ca_street_name,
    ca.ca_zip
  FROM full_demo fd
  LEFT JOIN customer_address ca
    ON fd.sr_addr_sk = ca.ca_address_sk
)
SELECT
  concat(ca_city, ', ', ca_state) AS city_state,
  regexp_extract(ca_street_name, '(\\w+)') AS street_first_word,
  SUM(sr_return_amt) AS total_return_amt,
  COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
  AVG(sr_fee) AS avg_fee,
  demo_cnt,
  avg_dep_employed
FROM joined_all
WHERE
  ca_street_name IS NOT NULL
  AND regexp_like(ca_street_name, '^[0-9]+')
  AND ca_city LIKE 'A%'
  AND sr_fee > (SELECT AVG(sr_fee) FROM store_returns WHERE sr_fee > 0)
  AND sr_cdemo_sk IN (
    SELECT cd_demo_sk FROM customer_demographics WHERE cd_dep_employed_count > 1
    INTERSECT
    SELECT sr_cdemo_sk FROM store_returns WHERE sr_return_amt > 100
  )
GROUP BY
  ca_city,
  ca_state,
  ca_street_name,
  demo_cnt,
  avg_dep_employed
HAVING
  SUM(sr_return_amt) > (SELECT MAX(sr_return_amt) FROM store_returns) / 2
ORDER BY total_return_amt DESC
LIMIT 100
