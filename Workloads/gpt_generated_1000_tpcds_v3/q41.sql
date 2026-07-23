WITH sr_agg AS (
    SELECT
        sr_reason_sk,
        sr_cdemo_sk,
        sr_addr_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr_fee) AS total_fee,
        COUNT(*) AS return_count,
        AVG(sr_return_tax) AS avg_return_tax,
        MIN(sr_return_tax) AS min_return_tax,
        MAX(sr_return_tax) AS max_return_tax
    FROM store_returns
    WHERE sr_fee > 30.00
      AND sr_return_tax > 0.00
      AND sr_return_amt_inc_tax > 200.00
    GROUP BY sr_reason_sk, sr_cdemo_sk, sr_addr_sk
)
SELECT
    ca.ca_state,
    cd.cd_gender,
    r.r_reason_desc,
    SUM(sr_agg.total_return_amt_inc_tax) AS sum_return_amt_inc_tax,
    SUM(sr_agg.total_fee) AS sum_fee,
    SUM(sr_agg.return_count) AS total_returns,
    AVG(sr_agg.avg_return_tax) AS avg_return_tax,
    CASE
        WHEN SUM(sr_agg.total_return_amt_inc_tax) > 10000 THEN 'High'
        WHEN SUM(sr_agg.total_return_amt_inc_tax) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sr_agg.total_return_amt_inc_tax) DESC) AS gender_rank,
    COUNT(DISTINCT ca.ca_zip) AS distinct_zip_count
FROM sr_agg
JOIN reason r ON sr_agg.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd ON sr_agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON sr_agg.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -5.00
  AND ca.ca_zip = '40587     '
  AND r.r_reason_desc = 'Package was damaged'
  AND cd.cd_gender = 'M'
  AND EXISTS (
      SELECT 1 FROM store_returns sr2
      WHERE sr2.sr_addr_sk = ca.ca_address_sk
        AND sr2.sr_fee > 80.00
  )
GROUP BY ca.ca_state, cd.cd_gender, r.r_reason_desc
ORDER BY sum_return_amt_inc_tax DESC
LIMIT 100
