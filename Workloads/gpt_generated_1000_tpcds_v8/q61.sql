WITH returns_joined AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_account_credit,
        CASE WHEN wr.wr_return_amt >= 100 THEN 'High' ELSE 'Low' END AS amt_category
    FROM web_returns wr
    RIGHT OUTER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT
    r.d_year,
    r.d_quarter_seq,
    r.amt_category,
    COUNT(DISTINCT r.wr_order_number) AS distinct_orders,
    SUM(r.wr_return_amt) AS total_return_amt,
    SUM(r.wr_account_credit) AS total_account_credit
FROM returns_joined r
WHERE r.d_quarter_seq IN (5, 12)
GROUP BY r.d_year, r.d_quarter_seq, r.amt_category
HAVING SUM(r.wr_return_amt) > 500

UNION ALL

SELECT
    r.d_year,
    r.d_quarter_seq,
    r.amt_category,
    COUNT(DISTINCT r.wr_order_number) AS distinct_orders,
    SUM(r.wr_return_amt) AS total_return_amt,
    SUM(r.wr_account_credit) AS total_account_credit
FROM returns_joined r
WHERE r.d_quarter_seq NOT IN (5, 12)
  AND r.amt_category = 'Low'
GROUP BY r.d_year, r.d_quarter_seq, r.amt_category
HAVING COUNT(DISTINCT r.wr_order_number) >= 10

ORDER BY d_year DESC, d_quarter_seq, total_return_amt DESC
LIMIT 100
