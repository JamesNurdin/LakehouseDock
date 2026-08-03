WITH base AS (
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_returned_time_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_order_number,
    wr.wr_refunded_hdemo_sk,
    wr.wr_returning_hdemo_sk
  FROM web_returns wr
  WHERE wr.wr_return_amt > 100
    AND wr.wr_return_quantity >= 1
    AND wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
),
joined AS (
  SELECT
    d.d_year,
    s.s_state,
    cc.cc_state,
    cp.cp_type,
    ib.ib_upper_bound,
    ib.ib_lower_bound,
    b.wr_return_amt,
    b.wr_return_tax,
    b.wr_order_number,
    b.wr_return_quantity
  FROM base b
  JOIN date_dim d          ON b.wr_returned_date_sk = d.d_date_sk
  JOIN time_dim t          ON b.wr_returned_time_sk = t.t_time_sk
  JOIN household_demographics hd_ret ON b.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN household_demographics hd_ref ON b.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib      ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store s             ON s.s_closed_date_sk = d.d_date_sk
  JOIN call_center cc      ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN catalog_page cp     ON cp.cp_end_date_sk = d.d_date_sk
  WHERE t.t_hour BETWEEN 9 AND 17
    AND ib.ib_lower_bound >= 130001
    AND s.s_state = 'CA'
    AND cc.cc_state = 'TX'
    AND cp.cp_type = 'A'
),
aggregated AS (
  SELECT
    d_year,
    s_state,
    cc_state,
    cp_type,
    CASE WHEN ib_upper_bound > 150000 THEN 'High' ELSE 'Low' END AS income_category,
    SUM(wr_return_amt)               AS total_return_amt,
    AVG(wr_return_tax)               AS avg_return_tax,
    COUNT(DISTINCT wr_order_number)  AS distinct_orders,
    MIN(wr_return_amt)               AS min_return_amt,
    MAX(wr_return_amt)               AS max_return_amt
  FROM joined
  GROUP BY d_year, s_state, cc_state, cp_type, ib_upper_bound
  HAVING SUM(wr_return_amt) > 5000
)
SELECT
  a.d_year,
  a.s_state,
  a.cc_state,
  a.cp_type,
  a.income_category,
  a.total_return_amt,
  a.avg_return_tax,
  a.distinct_orders,
  a.min_return_amt,
  a.max_return_amt,
  ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amt DESC) AS rank_by_year,
  (SELECT AVG(wr_return_amt) FROM web_returns) AS overall_avg_return_amt
FROM aggregated a
ORDER BY a.total_return_amt DESC
LIMIT 100
