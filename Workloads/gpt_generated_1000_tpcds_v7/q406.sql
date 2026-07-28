WITH filtered AS (
    SELECT
        cc.cc_company_name,
        d.d_fy_week_seq,
        wr.wr_return_amt,
        wr.wr_reversed_charge,
        wr.wr_return_quantity
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE cc.cc_company_name = 'anti'
      AND d.d_fy_week_seq = 3
      AND wr.wr_returning_cdemo_sk = 1291615
      AND d.d_following_holiday = 'N'
      AND d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    cc_company_name,
    d_fy_week_seq,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_reversed_charge) AS avg_reversed_charge,
    COUNT(*) AS return_count,
    MIN(wr_return_quantity) AS min_quantity,
    MAX(wr_return_quantity) AS max_quantity
FROM filtered
GROUP BY cc_company_name, d_fy_week_seq
ORDER BY total_return_amount DESC
LIMIT 20
