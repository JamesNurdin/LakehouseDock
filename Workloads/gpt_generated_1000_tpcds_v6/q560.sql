WITH distinct_reasons AS (
    SELECT DISTINCT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%size%'
       OR r_reason_desc LIKE '%color%'
),
filtered AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_reason_sk,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_account_credit,
        d.d_year,
        d.d_month_seq,
        d.d_holiday,
        d.d_weekend,
        dr.r_reason_desc
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN distinct_reasons dr ON wr.wr_reason_sk = dr.r_reason_sk
    WHERE d.d_year = 2001
      AND d.d_holiday = 'N'
      AND d.d_weekend = 'N'
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND wr.wr_return_amt_inc_tax > 100
)
SELECT
    d_year,
    d_month_seq,
    r_reason_desc,
    SUM(wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS rank_by_year_return_amt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(wr_net_loss) DESC) AS rownum_by_year_net_loss
FROM filtered
GROUP BY d_year, d_month_seq, r_reason_desc
ORDER BY d_year, rank_by_year_return_amt
LIMIT 100
