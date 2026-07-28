WITH
  store_profit AS (
    SELECT
      s.s_state AS state,
      SUM(ss.ss_net_profit) AS amount,
      CAST('store_profit' AS VARCHAR) AS metric_type
    FROM
      tpcds.store_sales ss
      JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
      JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
      d.d_fy_year = 1912
      AND ib.ib_lower_bound >= 30000
    GROUP BY
      s.s_state
  ),
  web_return_loss AS (
    SELECT
      ca.ca_state AS state,
      SUM(wr.wr_net_loss) AS amount,
      CAST('web_return_loss' AS VARCHAR) AS metric_type
    FROM
      tpcds.web_returns wr
      JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
      JOIN tpcds.customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
      JOIN tpcds.household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
      JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
      d.d_fy_year = 1912
      AND ib.ib_lower_bound >= 30000
    GROUP BY
      ca.ca_state
  )
SELECT
  state,
  amount,
  metric_type
FROM (
  SELECT state, amount, metric_type FROM store_profit
  UNION ALL
  SELECT state, amount, metric_type FROM web_return_loss
) AS combined
ORDER BY
  state,
  metric_type
