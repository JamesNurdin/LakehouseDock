WITH aggregated_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_tax > 5
      AND cr_return_tax < 200
      AND cr_return_quantity >= 1
      AND cr_return_quantity <= 10
      AND cr_returning_hdemo_sk IN (
          SELECT cr_returning_hdemo_sk
          FROM catalog_returns
          WHERE cr_return_amount > 1000
      )
      AND cr_refunded_addr_sk NOT IN (
          SELECT cr_refunded_addr_sk
          FROM catalog_returns
          WHERE cr_refunded_cash > 5000
      )
    GROUP BY cr_returned_date_sk, cr_returned_time_sk
    HAVING SUM(cr_net_loss) > 10
)
SELECT
    ar.cr_returned_date_sk,
    td.t_time_id,
    td.t_hour,
    td.t_minute,
    td.t_sub_shift,
    ar.total_net_loss,
    ar.total_return_amount,
    ar.cnt_returns,
    RANK() OVER (PARTITION BY ar.cr_returned_date_sk ORDER BY ar.total_net_loss DESC) AS net_loss_rank,
    SUM(ar.total_return_amount) OVER (
        PARTITION BY ar.cr_returned_date_sk
        ORDER BY td.t_hour
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_return_amount,
    CASE
        WHEN ar.total_net_loss > 100 THEN 'High'
        ELSE 'Low'
    END AS net_loss_category
FROM aggregated_returns ar
JOIN time_dim td
    ON ar.cr_returned_time_sk = td.t_time_sk
WHERE td.t_sub_shift IN ('morning', 'afternoon')
  AND td.t_hour >= 8
  AND td.t_hour <= 18
  AND td.t_minute IN (2, 4, 14, 17, 19)
ORDER BY ar.cr_returned_date_sk, net_loss_rank
LIMIT 100
