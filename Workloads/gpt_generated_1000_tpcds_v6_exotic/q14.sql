WITH cs_agg AS (
  SELECT
    ib.ib_income_band_sk,
    concat(cast(ib.ib_lower_bound AS varchar), '-', cast(ib.ib_upper_bound AS varchar)) AS income_range,
    sum(cs.cs_net_profit) AS total_amount,
    'catalog_sales' AS source
  FROM catalog_sales cs
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE cs.cs_ext_list_price > 5000
    AND EXISTS (
      SELECT 1
      FROM catalog_page cp
      WHERE cp.cp_department = 'Electronics'
        AND cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    )
  GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),

sr_agg AS (
  SELECT
    ib.ib_income_band_sk,
    concat(cast(ib.ib_lower_bound AS varchar), '-', cast(ib.ib_upper_bound AS varchar)) AS income_range,
    sum(sr.sr_net_loss) AS total_amount,
    'store_returns' AS source
  FROM store_returns sr
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE sr.sr_store_credit > 100
    AND ib.ib_upper_bound IN (
      SELECT max(ib2.ib_upper_bound) FROM income_band ib2
    )
  GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)

SELECT income_range, source, total_amount
FROM cs_agg
UNION ALL
SELECT income_range, source, total_amount
FROM sr_agg
ORDER BY income_range, source
LIMIT 100
