WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_id AS cp_id,
        cp.cp_department AS department,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt
    FROM catalog_page cp
    JOIN web_returns wr
        ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type = 'Standard'
      AND cp.cp_catalog_page_number IN (1, 2, 3)
      AND wr.wr_return_amt > 0
    GROUP BY cp.cp_catalog_page_id, cp.cp_department
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    cp_id,
    department,
    total_return_amt,
    avg_return_amt,
    return_cnt,
    RANK() OVER (ORDER BY total_return_amt DESC) AS revenue_rank
FROM page_returns
ORDER BY total_return_amt DESC
LIMIT 50
