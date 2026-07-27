WITH high_loss AS (
    SELECT
        r.r_reason_desc,
        SUM(w.wr_net_loss) AS metric_value,
        COUNT(*) AS return_cnt
    FROM tpcds.web_returns w
    JOIN tpcds.reason r
        ON w.wr_reason_sk = r.r_reason_sk
    WHERE w.wr_return_amt > 100
      AND w.wr_return_ship_cost > 50
      AND w.wr_net_loss > 0
      AND w.wr_net_loss > (
          SELECT AVG(wr_net_loss)
          FROM tpcds.web_returns
      )
    GROUP BY r.r_reason_desc
    HAVING SUM(w.wr_net_loss) > 500
),
high_rev_charge AS (
    SELECT
        r.r_reason_desc,
        SUM(w.wr_reversed_charge) AS metric_value,
        COUNT(*) AS return_cnt
    FROM tpcds.web_returns w
    JOIN tpcds.reason r
        ON w.wr_reason_sk = r.r_reason_sk
    WHERE w.wr_reversed_charge > 100
      AND EXISTS (
          SELECT 1
          FROM tpcds.web_returns w2
          WHERE w2.wr_returning_hdemo_sk = w.wr_returning_hdemo_sk
            AND w2.wr_return_amt > 200
      )
    GROUP BY r.r_reason_desc
)
SELECT *
FROM high_loss
UNION ALL
SELECT *
FROM high_rev_charge
ORDER BY metric_value DESC
