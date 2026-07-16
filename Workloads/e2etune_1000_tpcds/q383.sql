WITH agg AS (
    SELECT
        cp.cp_type,
        cp.cp_department,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_fee) AS total_fee
    FROM catalog_page cp
    JOIN web_returns wr
        ON wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND cp.cp_start_date_sk >= 2450800
    GROUP BY cp.cp_type, cp.cp_department
)
SELECT
    cp_type,
    cp_department,
    return_cnt,
    total_return_amt,
    avg_net_loss,
    total_fee,
    total_return_amt / SUM(total_return_amt) OVER (PARTITION BY cp_type) AS dept_return_share
FROM agg
WHERE return_cnt > 10
ORDER BY total_return_amt DESC
LIMIT 100
