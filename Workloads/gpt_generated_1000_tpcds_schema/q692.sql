WITH
  sub_a AS (
    SELECT
      sr.sr_return_amt,
      sr.sr_ticket_number,
      ca.ca_state,
      hd.hd_buy_potential
    FROM tpcds.store_returns sr
    TABLESAMPLE BERNOULLI (5)
    JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_state = 'CA'
      AND hd.hd_dep_count >= 2
  ),
  sub_b AS (
    SELECT
      sr.sr_return_amt,
      sr.sr_ticket_number,
      ca.ca_state,
      hd.hd_buy_potential
    FROM tpcds.store_returns sr
    TABLESAMPLE BERNOULLI (5)
    JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_county LIKE '%County'
      AND hd.hd_vehicle_count > 0
  ),
  unioned AS (
    SELECT ca_state, hd_buy_potential, sr_return_amt, sr_ticket_number FROM sub_a
    UNION
    SELECT ca_state, hd_buy_potential, sr_return_amt, sr_ticket_number FROM sub_b
  )
SELECT
  ca_state,
  hd_buy_potential,
  SUM(sr_return_amt) AS total_return_amt,
  COUNT(*) AS return_cnt,
  (SELECT AVG(sr_return_amt) FROM tpcds.store_returns) AS avg_return_overall,
  ROW_NUMBER() OVER (ORDER BY SUM(sr_return_amt) DESC) AS rn
FROM unioned
GROUP BY ROLLUP (ca_state, hd_buy_potential)
ORDER BY ca_state, hd_buy_potential NULLS LAST, total_return_amt DESC
