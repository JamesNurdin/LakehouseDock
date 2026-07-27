WITH store_monthly AS (
  SELECT
    d.d_month_seq AS month_seq,
    SUM(ss.ss_net_profit) AS total_profit,
    'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = 2001
    AND ib.ib_lower_bound >= 50000
  GROUP BY d.d_month_seq
),
web_monthly AS (
  SELECT
    d.d_month_seq AS month_seq,
    SUM(ws.ws_net_profit) AS total_profit,
    'web' AS channel,
    (
      SELECT COUNT(*)
      FROM inventory inv
      WHERE inv.inv_date_sk = d.d_date_sk
    ) AS inventory_count
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = 2001
    AND ib.ib_lower_bound >= 50000
  GROUP BY d.d_month_seq, d.d_date_sk
)
SELECT
  month_seq,
  total_profit,
  channel,
  CASE WHEN channel = 'web' THEN inventory_count END AS inventory_count
FROM (
  SELECT month_seq, total_profit, channel, inventory_count FROM web_monthly
  UNION ALL
  SELECT month_seq, total_profit, channel, NULL AS inventory_count FROM store_monthly
) AS combined
ORDER BY month_seq, channel
LIMIT 100
