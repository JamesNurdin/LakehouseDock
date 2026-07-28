WITH catalog_agg AS (
  SELECT
    cp.cp_department AS category,
    SUM(cs.cs_net_profit) AS total_amount,
    COUNT(*) AS cnt
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cp.cp_description LIKE '%summer%'
    AND cd.cd_gender = 'M'
    AND concat(cd.cd_gender, cd.cd_marital_status) = 'MS'
    AND EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_cdemo_sk = cd.cd_demo_sk
        AND sr2.sr_net_loss > 1000
    )
  GROUP BY cp.cp_department
),
store_agg AS (
  SELECT
    r.r_reason_desc AS category,
    SUM(sr.sr_net_loss) AS total_amount,
    COUNT(*) AS cnt
  FROM store_returns sr
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE regexp_like(r.r_reason_desc, '^Did not.*time$')
    AND substring(r.r_reason_desc, 1, 3) = 'Did'
    AND cd.cd_marital_status = 'M'
  GROUP BY r.r_reason_desc
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM store_agg
ORDER BY total_amount DESC
LIMIT 100
