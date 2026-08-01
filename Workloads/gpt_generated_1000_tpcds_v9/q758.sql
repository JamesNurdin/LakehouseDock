/*
Goal: Compare total net loss and return metrics for refunded vs. returning customers by demographic segment.
We aggregate net loss, return count, and average return amount for two demographic groups (married and single) and combine the results using UNION ALL.
A scalar subquery filters refunded returns above the overall average return amount, and an EXISTS subquery ensures returning customers have at least one related return with tax > 20.00.
Only groups with total net loss > 1000 are kept, and the final result is ordered by total net loss descending.
*/
SELECT
  cd.cd_demo_sk,
  cd.cd_marital_status,
  cd.cd_dep_count,
  'refunded' AS return_type,
  SUM(wr.wr_net_loss) AS total_net_loss,
  COUNT(*) AS return_cnt,
  AVG(wr.wr_return_amt) AS avg_return_amt
FROM web_returns wr
JOIN customer_demographics cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status = 'M'
  AND cd.cd_dep_count BETWEEN 2 AND 5
  AND wr.wr_return_amt > (
        SELECT AVG(wr_inner.wr_return_amt)
        FROM web_returns wr_inner
      )
GROUP BY cd.cd_demo_sk, cd.cd_marital_status, cd.cd_dep_count
HAVING SUM(wr.wr_net_loss) > 1000

UNION ALL

SELECT
  cd.cd_demo_sk,
  cd.cd_marital_status,
  cd.cd_dep_count,
  'returning' AS return_type,
  SUM(wr.wr_net_loss) AS total_net_loss,
  COUNT(*) AS return_cnt,
  AVG(wr.wr_return_amt) AS avg_return_amt
FROM web_returns wr
JOIN customer_demographics cd
  ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status = 'S'
  AND cd.cd_dep_employed_count > 1
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = wr.wr_order_number
          AND wr2.wr_return_tax > 20.00
      )
GROUP BY cd.cd_demo_sk, cd.cd_marital_status, cd.cd_dep_count
HAVING SUM(wr.wr_net_loss) > 1000

ORDER BY total_net_loss DESC
LIMIT 100
