WITH returns_with_date AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_tax,
        wr.wr_return_quantity,
        wr.wr_returned_time_sk,
        d.d_year,
        d.d_month_seq,
        d.d_date
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND wr.wr_return_amt_inc_tax > 500
      AND wr.wr_return_quantity >= 2
      AND wr.wr_returned_time_sk BETWEEN 30000 AND 50000
)
SELECT
    r.d_year,
    r.d_month_seq,
    COALESCE(ws.web_name, 'UNKNOWN') AS web_name,
    COALESCE(ws.web_state, 'UNKNOWN') AS web_state,
    COUNT(*) AS returns_cnt,
    SUM(r.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    AVG(r.wr_return_tax) AS avg_return_tax,
    MIN(r.wr_return_quantity) AS min_return_qty,
    MAX(r.wr_return_quantity) AS max_return_qty
FROM returns_with_date r
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = r.wr_returned_date_sk
   AND ws.web_gmt_offset = -5.00
GROUP BY
    r.d_year,
    r.d_month_seq,
    COALESCE(ws.web_name, 'UNKNOWN'),
    COALESCE(ws.web_state, 'UNKNOWN')
ORDER BY total_return_amt_inc_tax DESC
LIMIT 100
