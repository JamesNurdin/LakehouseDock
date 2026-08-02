WITH RECURSIVE date_hierarchy (d_date_sk, d_fy_week_seq, d_quarter_name, d_year) AS (
    SELECT d_date_sk, d_fy_week_seq, d_quarter_name, d_year
    FROM date_dim
    WHERE d_quarter_name = '1904Q1' AND d_fy_week_seq = 1
    UNION ALL
    SELECT d2.d_date_sk, d2.d_fy_week_seq, d2.d_quarter_name, d2.d_year
    FROM date_dim d2
    JOIN date_hierarchy dh ON d2.d_fy_week_seq = dh.d_fy_week_seq + 1
    WHERE d2.d_quarter_name = '1904Q1' AND d2.d_fy_week_seq <= 10
)
SELECT
    dh.d_quarter_name,
    dh.d_year,
    dh.d_fy_week_seq,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    MIN(wr.wr_return_quantity) AS min_return_qty,
    MAX(wr.wr_return_quantity) AS max_return_qty,
    (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2) AS overall_avg_return_amt
FROM date_hierarchy dh
JOIN web_returns wr ON wr.wr_returned_date_sk = dh.d_date_sk
WHERE wr.wr_return_amt > 100.00
  AND wr.wr_return_tax BETWEEN 5.00 AND 30.00
  AND wr.wr_return_quantity <= 5
  AND dh.d_fy_week_seq IN (2, 5, 7, 9)
GROUP BY dh.d_quarter_name, dh.d_year, dh.d_fy_week_seq

UNION

SELECT
    dh.d_quarter_name,
    dh.d_year,
    dh.d_fy_week_seq,
    COUNT(*) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    MIN(wr.wr_return_quantity) AS min_return_qty,
    MAX(wr.wr_return_quantity) AS max_return_qty,
    (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2) AS overall_avg_return_amt
FROM date_hierarchy dh
JOIN web_returns wr ON wr.wr_returned_date_sk = dh.d_date_sk
WHERE wr.wr_return_amt > 200.00
  AND wr.wr_return_tax BETWEEN 10.00 AND 25.00
  AND wr.wr_return_quantity <= 3
  AND dh.d_fy_week_seq IN (3, 6, 8, 10)
GROUP BY dh.d_quarter_name, dh.d_year, dh.d_fy_week_seq
LIMIT 100
