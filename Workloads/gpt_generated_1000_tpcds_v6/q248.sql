WITH hd_agg AS (
  SELECT
    hd.hd_demo_sk,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
  FROM catalog_returns cr
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE cr.cr_return_amount > 100
    AND cr.cr_return_quantity BETWEEN 1 AND 5
    AND ib.ib_upper_bound <= 120000
  GROUP BY hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
  HAVING SUM(cr.cr_return_amount) > 500
),
ws_agg AS (
  SELECT
    ws.ws_bill_hdemo_sk AS hd_demo_sk,
    SUM(ws.ws_ext_sales_price) AS sales_amount,
    MIN(ws.ws_web_site_sk) AS web_site_sk
  FROM web_sales ws
  WHERE ws.ws_net_profit > 0
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
  GROUP BY ws.ws_bill_hdemo_sk
)
SELECT
  hd_agg.hd_demo_sk,
  hd_agg.ib_income_band_sk,
  hd_agg.ib_lower_bound,
  hd_agg.ib_upper_bound,
  hd_agg.total_return_amount,
  hd_agg.total_net_loss,
  ws_agg.sales_amount,
  (hd_agg.total_return_amount + ws_agg.sales_amount) AS combined_amount,
  RANK() OVER (
    PARTITION BY hd_agg.ib_income_band_sk
    ORDER BY (hd_agg.total_return_amount + ws_agg.sales_amount) DESC
  ) AS rank_in_income_band,
  CASE
    WHEN (hd_agg.total_return_amount + ws_agg.sales_amount) > 2000 THEN 'High'
    WHEN (hd_agg.total_return_amount + ws_agg.sales_amount) > 1000 THEN 'Medium'
    ELSE 'Low'
  END AS tier,
  ws_site.web_site_id,
  ws_site.web_market_manager,
  (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper_bound
FROM hd_agg
JOIN ws_agg
  ON ws_agg.hd_demo_sk = hd_agg.hd_demo_sk
JOIN web_site ws_site
  ON ws_agg.web_site_sk = ws_site.web_site_sk
WHERE ws_site.web_tax_percentage >= 0.05
ORDER BY hd_agg.ib_income_band_sk, rank_in_income_band
LIMIT 100
