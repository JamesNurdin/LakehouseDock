WITH refunded_preferred AS (
   SELECT t.t_meal_time,
          'RefundedPreferred' AS return_type,
          SUM(wr.wr_net_loss) AS total_net_loss,
          COUNT(*) AS num_returns
   FROM web_returns wr
   JOIN time_dim t
     ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN customer c
     ON wr.wr_refunded_customer_sk = c.c_customer_sk
   WHERE c.c_preferred_cust_flag = 'Y'
   GROUP BY t.t_meal_time
),
returning_nonpreferred AS (
   SELECT t.t_meal_time,
          'ReturningNonPreferred' AS return_type,
          SUM(wr.wr_net_loss) AS total_net_loss,
          COUNT(*) AS num_returns
   FROM web_returns wr
   JOIN time_dim t
     ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN customer c
     ON wr.wr_returning_customer_sk = c.c_customer_sk
   WHERE c.c_preferred_cust_flag = 'N'
   GROUP BY t.t_meal_time
)
SELECT
   combined.t_meal_time,
   combined.return_type,
   combined.total_net_loss,
   combined.num_returns
FROM (
   SELECT t_meal_time, return_type, total_net_loss, num_returns FROM refunded_preferred
   UNION ALL
   SELECT t_meal_time, return_type, total_net_loss, num_returns FROM returning_nonpreferred
) AS combined
ORDER BY combined.t_meal_time, combined.total_net_loss DESC
OFFSET 0 LIMIT 100
