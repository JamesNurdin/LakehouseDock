WITH base AS (
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    wr.wr_return_amt,
    hd_ref.hd_buy_potential,
    hd_ret.hd_vehicle_count
  FROM date_dim d
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  WHERE d.d_year = 2001
    AND d.d_current_month = 'Y'
    AND i.i_manufact_id IN (220, 117)
    AND hd_ref.hd_buy_potential = '>10000'
    AND hd_ret.hd_vehicle_count >= 1
),
agg AS (
  SELECT
    d_year,
    i_item_id,
    i_product_name,
    SUM(wr_return_amt) AS total_return_amt
  FROM base
  GROUP BY d_year, i_item_id, i_product_name
  HAVING SUM(wr_return_amt) > 1000
)
SELECT
  d_year,
  i_item_id,
  i_product_name,
  total_return_amt,
  RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rank_in_year
FROM agg
ORDER BY d_year, rank_in_year
LIMIT 100
