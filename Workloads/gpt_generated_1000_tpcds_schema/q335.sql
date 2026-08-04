WITH
  sampled_returns AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
    WHERE wr_return_amt > 1000
      AND wr_return_ship_cost > 0
      AND wr_return_quantity >= 1
      AND wr_returned_date_sk IS NOT NULL
  ),
  primary_orders AS (
    SELECT wr_order_number
    FROM sampled_returns
    WHERE wr_return_amt > 1500
  ),
  excluded_orders AS (
    SELECT wr_order_number
    FROM sampled_returns
    WHERE wr_return_amt < 2000
  )
SELECT
  d.d_year,
  ca_ref.ca_state AS refunded_state,
  ca_ret.ca_state AS returning_state,
  hd_ref.hd_buy_potential,
  COUNT(DISTINCT sr.wr_order_number) AS order_cnt,
  SUM(sr.wr_return_amt) AS total_return_amount,
  AVG(sr.wr_return_ship_cost) AS avg_ship_cost,
  MIN(sr.wr_return_amt) AS min_return_amount,
  MAX(sr.wr_return_amt) AS max_return_amount
FROM sampled_returns sr
JOIN date_dim d
  ON sr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_ref
  ON sr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
  ON sr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN household_demographics hd_ref
  ON sr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
  ON sr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND d.d_fy_quarter_seq = 5
  AND ca_ref.ca_state = 'CA'
  AND ca_ret.ca_state = 'TX'
  AND hd_ref.hd_buy_potential = '1001-5000'
  AND hd_ret.hd_dep_count <= 5
  AND sr.wr_order_number IN (
    SELECT wr_order_number FROM primary_orders
    EXCEPT
    SELECT wr_order_number FROM excluded_orders
  )
GROUP BY
  d.d_year,
  ca_ref.ca_state,
  ca_ret.ca_state,
  hd_ref.hd_buy_potential
ORDER BY total_return_amount DESC
LIMIT 100
