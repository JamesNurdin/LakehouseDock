WITH web_returns_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(wr.wr_return_amt) AS metric_value,
        'web_return' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%size%'
      AND d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
call_center_closed_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        COUNT(cc.cc_call_center_sk) AS metric_value,
        'call_center_closed' AS source
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_employees > 10
    GROUP BY d.d_year, d.d_month_seq
)
SELECT year,
       month_seq,
       metric_value,
       source
FROM web_returns_monthly
UNION ALL
SELECT year,
       month_seq,
       metric_value,
       source
FROM call_center_closed_monthly
ORDER BY year, month_seq, source
