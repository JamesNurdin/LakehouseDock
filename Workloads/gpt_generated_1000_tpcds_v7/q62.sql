WITH store_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        AVG(sr.sr_fee) AS avg_store_fee,
        COUNT(*) AS store_return_cnt,
        MAX(sr.sr_return_tax) AS max_store_tax
    FROM store_returns sr
    WHERE sr.sr_fee > 30
    GROUP BY sr.sr_returned_date_sk
),
web_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        AVG(wr.wr_return_tax) AS avg_web_tax,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    WHERE wr.wr_return_tax < 10
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    d.d_dow,
    sa.total_store_return_amt,
    wa.total_web_return_amt,
    (sa.total_store_return_amt + wa.total_web_return_amt) AS total_combined_return_amt,
    sa.avg_store_fee,
    wa.avg_web_tax,
    (sa.store_return_cnt + wa.web_return_cnt) AS total_returns,
    RANK() OVER (PARTITION BY d.d_year ORDER BY (sa.total_store_return_amt + wa.total_web_return_amt) DESC) AS rank_within_year,
    (SELECT AVG(sr2.sr_fee) FROM store_returns sr2) AS overall_avg_store_fee
FROM store_agg sa
JOIN date_dim d ON sa.sr_returned_date_sk = d.d_date_sk
JOIN web_agg wa ON wa.wr_returned_date_sk = d.d_date_sk
WHERE d.d_quarter_name = '1902Q3'
  AND d.d_dow = 3
  AND d.d_current_quarter = 'Y'
  AND d.d_year BETWEEN 1999 AND 2001
ORDER BY d.d_year, rank_within_year
LIMIT 100
