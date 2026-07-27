SELECT
    ib.ib_income_band_sk,
    CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_range,
    'web' AS source,
    SUM(ws.ws_net_profit) AS total_amount,
    (
        SELECT MAX(ws2.ws_ext_tax)
        FROM web_sales ws2
        INNER JOIN household_demographics hd2 ON ws2.ws_bill_hdemo_sk = hd2.hd_demo_sk
        INNER JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
        WHERE ib2.ib_income_band_sk = ib.ib_income_band_sk
    ) AS max_tax
FROM web_sales ws
INNER JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE ws.ws_ext_wholesale_cost > 1000
  AND ws_site.web_street_type = 'Ave'
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound

UNION ALL

SELECT
    ib.ib_income_band_sk,
    CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_range,
    'store' AS source,
    SUM(sr.sr_net_loss) AS total_amount,
    NULL AS max_tax
FROM store_returns sr
INNER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE sr.sr_return_amt > 100
  AND hd.hd_vehicle_count > 1
  AND EXISTS (
        SELECT 1
        FROM web_sales ws3
        INNER JOIN household_demographics hd3 ON ws3.ws_bill_hdemo_sk = hd3.hd_demo_sk
        WHERE hd3.hd_income_band_sk = ib.ib_income_band_sk
      )
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound

ORDER BY total_amount DESC
LIMIT 100
