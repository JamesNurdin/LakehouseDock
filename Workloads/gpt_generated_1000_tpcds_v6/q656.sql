WITH returns_summary AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%defect%'
      AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
      AND wr.wr_return_amt > 50
      AND d.d_current_month = 'Y'
    GROUP BY r.r_reason_id, r.r_reason_desc, d.d_year, d.d_month_seq
)
SELECT
    rs.r_reason_id,
    rs.r_reason_desc,
    rs.d_year,
    rs.d_month_seq,
    rs.total_return_amt,
    rs.return_cnt,
    rs.avg_return_amt,
    CASE
        WHEN rs.total_return_amt > (SELECT AVG(wr_return_amt) FROM web_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_category
FROM returns_summary rs
WHERE rs.return_cnt >= 10
ORDER BY rs.total_return_amt DESC
LIMIT 100
