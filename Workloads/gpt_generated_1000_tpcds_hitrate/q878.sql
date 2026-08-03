WITH cs AS (
  SELECT
    c.c_customer_id,
    'catalog' AS source,
    cs.cs_ext_sales_price AS net_amount,
    CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'high' ELSE 'medium' END AS amount_bucket,
    (
      SELECT MAX(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
    ) AS extra_metric,
    ROW_NUMBER() OVER (ORDER BY cs.cs_ext_sales_price DESC) AS rn_sub
  FROM catalog_sales cs
  RIGHT OUTER JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE c.c_birth_year BETWEEN 1960 AND 1970
    AND EXISTS (
      SELECT 1
      FROM household_demographics hd
      WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
        AND hd.hd_income_band_sk = 5
    )
),
sr AS (
  SELECT
    c.c_customer_id,
    'store_return' AS source,
    sr.sr_return_amt AS net_amount,
    CASE WHEN sr.sr_return_amt > 500 THEN 'high' ELSE 'medium' END AS amount_bucket,
    CAST(
      (SELECT COUNT(*)
       FROM store_returns sr2
       WHERE sr2.sr_customer_sk = c.c_customer_sk) AS decimal(12,2)
    ) AS extra_metric,
    ROW_NUMBER() OVER (ORDER BY sr.sr_return_amt DESC) AS rn_sub
  FROM store_returns sr
  RIGHT OUTER JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  WHERE (r.r_reason_desc LIKE '%defect%' OR r.r_reason_desc IS NULL)
    AND c.c_birth_month = 7
)
SELECT
  final.c_customer_id AS customer_id,
  final.source,
  final.net_amount,
  final.amount_bucket,
  final.extra_metric,
  final.rn_sub,
  ROW_NUMBER() OVER (ORDER BY final.source, final.net_amount DESC) AS overall_rn
FROM (
  SELECT * FROM cs
  UNION ALL
  SELECT * FROM sr
) AS final
ORDER BY final.source, final.net_amount DESC
