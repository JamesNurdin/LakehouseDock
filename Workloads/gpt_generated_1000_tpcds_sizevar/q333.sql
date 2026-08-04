WITH sales_data AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_hdemo_sk,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    ss.ss_ext_sales_price,
    ss.ss_net_profit
  FROM store_sales ss
  JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
  JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN income_band ib ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
),
returns_data AS (
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_returned_time_sk,
    wr.wr_refunded_hdemo_sk,
    wr.wr_returning_hdemo_sk,
    wr.wr_return_amt,
    wr.wr_net_loss
  FROM web_returns wr
  JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t_ret ON wr.wr_returned_time_sk = t_ret.t_time_sk
  JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
)
SELECT
  d_year,
  s_state,
  p_promo_name,
  SUM(total_sales) AS total_sales,
  SUM(total_profit) AS total_profit,
  SUM(total_returns) AS total_returns
FROM (
  SELECT
    d_sales.d_year AS d_year,
    s.s_state AS s_state,
    p.p_promo_name AS p_promo_name,
    sd.ss_ext_sales_price AS total_sales,
    sd.ss_net_profit AS total_profit,
    0.0 AS total_returns
  FROM sales_data sd
  JOIN date_dim d_sales ON sd.ss_sold_date_sk = d_sales.d_date_sk
  JOIN store s ON sd.ss_store_sk = s.s_store_sk
  JOIN promotion p ON sd.ss_promo_sk = p.p_promo_sk

  UNION DISTINCT

  SELECT
    d_ret.d_year AS d_year,
    s_dummy.s_state AS s_state,
    'No Promo' AS p_promo_name,
    0.0 AS total_sales,
    0.0 AS total_profit,
    rd.wr_return_amt AS total_returns
  FROM returns_data rd
  JOIN date_dim d_ret ON rd.wr_returned_date_sk = d_ret.d_date_sk
  CROSS JOIN (SELECT DISTINCT s_state FROM store LIMIT 5) AS s_dummy
  CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2) AS calc_set
) AS combined
GROUP BY d_year, s_state, p_promo_name
ORDER BY total_sales DESC, d_year
LIMIT 100
