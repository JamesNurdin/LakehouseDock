WITH
  catalog_agg AS (
    SELECT
      d.d_year,
      d.d_moy,
      SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(hd.hd_buy_potential, '(?i)high|medium')
      AND d.d_quarter_name LIKE '%Q1%'
    GROUP BY d.d_year, d.d_moy
  ),
  web_agg AS (
    SELECT
      d.d_year,
      d.d_moy,
      SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(hd.hd_buy_potential, '(?i)high|medium')
      AND d.d_quarter_name LIKE '%Q1%'
    GROUP BY d.d_year, d.d_moy
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      d.d_moy,
      SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(hd.hd_buy_potential, '(?i)high|medium')
      AND d.d_quarter_name LIKE '%Q1%'
    GROUP BY d.d_year, d.d_moy
  )
SELECT
  CONCAT('Month ', CAST(COALESCE(ca.d_moy, wa.d_moy, ra.d_moy) AS VARCHAR), '-', CAST(COALESCE(ca.d_year, wa.d_year, ra.d_year) AS VARCHAR)) AS month_label,
  COALESCE(ca.d_year, wa.d_year, ra.d_year) AS year,
  COALESCE(ca.d_moy, wa.d_moy, ra.d_moy) AS month,
  ca.catalog_profit,
  wa.web_profit,
  ra.return_loss,
  (COALESCE(ca.catalog_profit, 0) + COALESCE(wa.web_profit, 0) - COALESCE(ra.return_loss, 0)) AS net_profit_after_returns,
  REGEXP_EXTRACT(dsample.d_date_id, '(\\d{4})$') AS extracted_suffix
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
  ON ca.d_year = wa.d_year AND ca.d_moy = wa.d_moy
FULL OUTER JOIN returns_agg ra
  ON COALESCE(ca.d_year, wa.d_year) = ra.d_year
 AND COALESCE(ca.d_moy, wa.d_moy) = ra.d_moy
LEFT JOIN (
  SELECT d_date_id, d_year, d_moy
  FROM date_dim
  WHERE d_quarter_name LIKE '%Q1%'
  LIMIT 1
) dsample
  ON dsample.d_year = COALESCE(ca.d_year, wa.d_year, ra.d_year)
 AND dsample.d_moy = COALESCE(ca.d_moy, wa.d_moy, ra.d_moy)
ORDER BY year DESC, month DESC
LIMIT 100
