WITH
  full_cr AS (
    SELECT
      cr.cr_reason_sk,
      cr.cr_ship_mode_sk,
      sm.sm_carrier,
      r.r_reason_desc,
      SUM(cr.cr_return_amount) AS sum_return_amount,
      COUNT(*) AS cnt_returns,
      CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'Large' ELSE 'Small' END AS size_category
    FROM catalog_returns cr
    FULL OUTER JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > (
          SELECT MIN(cr_return_amount)
          FROM catalog_returns
          WHERE cr_return_amount > 0
        )
    GROUP BY GROUPING SETS (
      (cr.cr_reason_sk, cr.cr_ship_mode_sk, sm.sm_carrier, r.r_reason_desc),
      (cr.cr_reason_sk, sm.sm_carrier, r.r_reason_desc),
      (cr.cr_ship_mode_sk, sm.sm_carrier, r.r_reason_desc)
    )
  ),
  web_agg AS (
    SELECT
      wr.wr_reason_sk,
      r.r_reason_desc,
      SUM(wr.wr_return_amt) AS sum_return_amt,
      COUNT(*) AS cnt_returns,
      CASE WHEN AVG(wr.wr_return_tax) > 100 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM web_returns wr
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_tax > (
          SELECT MAX(wr_return_tax)
          FROM web_returns
          WHERE wr_return_tax < 500
        )
    GROUP BY GROUPING SETS (
      (wr.wr_reason_sk, r.r_reason_desc),
      (r.r_reason_desc)
    )
  )
SELECT
  combined.reason_sk,
  combined.ship_mode_sk,
  combined.sm_carrier,
  combined.r_reason_desc,
  combined.total_amount,
  combined.cnt_returns,
  combined.category,
  combined.tax_category
FROM (
  SELECT
    fr.cr_reason_sk AS reason_sk,
    fr.cr_ship_mode_sk AS ship_mode_sk,
    fr.sm_carrier,
    fr.r_reason_desc,
    fr.sum_return_amount AS total_amount,
    fr.cnt_returns,
    fr.size_category AS category,
    NULL AS tax_category
  FROM full_cr fr
  UNION ALL
  SELECT
    wa.wr_reason_sk AS reason_sk,
    NULL AS ship_mode_sk,
    NULL AS sm_carrier,
    wa.r_reason_desc,
    wa.sum_return_amt AS total_amount,
    wa.cnt_returns,
    NULL AS category,
    wa.tax_category
  FROM web_agg wa
) AS combined
LIMIT 100
