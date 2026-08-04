WITH filtered_returns AS (
  SELECT wr.*
  FROM web_returns wr
  WHERE wr.wr_return_amt > 10
    AND wr.wr_return_quantity >= 1
    AND wr.wr_return_tax IS NOT NULL
    AND wr.wr_fee < 20
    AND wr.wr_return_ship_cost BETWEEN 0 AND 15
    AND wr.wr_net_loss > 0
),
order_numbers_to_exclude AS (
  SELECT wr.wr_order_number
  FROM web_returns wr
  WHERE wr.wr_return_amt = 0
),
eligible_orders AS (
  SELECT wr.wr_order_number
  FROM filtered_returns wr
  EXCEPT
  SELECT wr_ex.wr_order_number
  FROM web_returns wr_ex
  WHERE wr_ex.wr_return_amt = 0
),
base AS (
  SELECT
    wr.wr_order_number,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_fee,
    wr.wr_return_ship_cost,
    wr.wr_net_loss,
    hd_ref.hd_income_band_sk,
    hd_ref.hd_buy_potential,
    ca_ref.ca_state,
    ca_ref.ca_gmt_offset,
    CASE
      WHEN hd_ref.hd_buy_potential LIKE '0-500'   THEN 'Low'
      WHEN hd_ref.hd_buy_potential LIKE '501-1000' THEN 'Medium'
      ELSE 'High'
    END AS buy_potential_category
  FROM filtered_returns wr
  JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
  WHERE EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_order_number = wr.wr_order_number
            AND wr2.wr_return_amt > 0
        )
    AND wr.wr_order_number IN (SELECT wr_order_number FROM eligible_orders)
)
SELECT
  b.wr_order_number,
  b.wr_return_amt,
  b.wr_return_tax,
  b.wr_fee,
  b.wr_return_ship_cost,
  b.wr_net_loss,
  b.hd_income_band_sk,
  b.hd_buy_potential,
  b.buy_potential_category,
  b.ca_state,
  b.ca_gmt_offset,
  ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY b.wr_return_amt DESC) AS rn_state,
  SUM(b.wr_return_amt) OVER (
        PARTITION BY b.hd_income_band_sk
        ORDER BY b.wr_order_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS cumulative_return_amt_by_income
FROM base b
UNION DISTINCT
SELECT
  b.wr_order_number,
  b.wr_return_amt,
  b.wr_return_tax,
  b.wr_fee,
  b.wr_return_ship_cost,
  b.wr_net_loss,
  b.hd_income_band_sk,
  b.hd_buy_potential,
  b.buy_potential_category,
  b.ca_state,
  b.ca_gmt_offset,
  ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY b.wr_return_amt ASC) AS rn_state,
  SUM(b.wr_return_amt) OVER (
        PARTITION BY b.hd_income_band_sk
        ORDER BY b.wr_order_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS cumulative_return_amt_by_income
FROM base b
ORDER BY rn_state ASC, wr_return_amt DESC
LIMIT 100
