WITH store_returns_agg AS (
    SELECT
        sr.sr_store_sk AS sr_store_sk,
        d.d_year AS d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND d.d_month_seq IN (1, 2, 3)
      AND d.d_week_seq >= 10
      AND d.d_fy_week_seq <= 20
      AND d.d_fy_week_seq >= 5
      AND d.d_week_seq <= 30
    GROUP BY sr.sr_store_sk, d.d_year
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    s.s_store_id,
    agg.d_year,
    agg.total_return_amt,
    agg.total_return_tax,
    agg.return_cnt,
    s.s_state,
    s.s_tax_percentage,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_return_amt DESC) AS rn,
    CASE
        WHEN agg.total_return_tax > (
            SELECT MAX(sr2.sr_return_tax)
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
        ) THEN 'HIGH_TAX'
        ELSE 'NORMAL_TAX'
    END AS tax_category
FROM store_returns_agg agg
JOIN store s ON agg.sr_store_sk = s.s_store_sk
WHERE s.s_tax_percentage >= 0.05
  AND s.s_state = 'CA'
  AND s.s_city IN ('Los Angeles', 'San Francisco')
  AND s.s_number_employees > 50
  AND s.s_floor_space BETWEEN 2000 AND 5000
  AND s.s_gmt_offset = -8.00
ORDER BY agg.d_year, rn
LIMIT 100
