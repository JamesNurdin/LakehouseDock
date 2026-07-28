WITH
  store_agg AS (
    SELECT
      sr_cdemo_sk,
      sr_hdemo_sk,
      sr_return_time_sk,
      SUM(sr_net_loss) AS total_net_loss,
      COUNT(*) AS store_return_cnt
    FROM store_returns
    WHERE sr_net_loss > 20
      AND sr_fee < 80
      AND sr_return_quantity > 1
    GROUP BY sr_cdemo_sk, sr_hdemo_sk, sr_return_time_sk
  ),
  web_agg AS (
    SELECT
      wr_returned_time_sk,
      SUM(wr_net_loss) AS total_net_loss,
      COUNT(*) AS web_return_cnt,
      wr_refunded_cdemo_sk,
      wr_refunded_hdemo_sk
    FROM web_returns
    WHERE wr_return_quantity > 2
      AND wr_return_amt > 5
      AND wr_return_tax < 30
    GROUP BY wr_returned_time_sk, wr_refunded_cdemo_sk, wr_refunded_hdemo_sk
  ),
  combined AS (
    SELECT
      cd.cd_gender      AS gender,
      t.t_meal_time     AS meal_time,
      sa.total_net_loss AS loss_amount
    FROM store_agg sa
    JOIN customer_demographics cd ON sa.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sa.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON sa.sr_return_time_sk = t.t_time_sk
    WHERE cd.cd_gender IN ('M', 'F')
      AND t.t_meal_time IN ('breakfast', 'lunch', 'dinner')
    UNION ALL
    SELECT
      cd2.cd_gender      AS gender,
      t2.t_meal_time     AS meal_time,
      wa.total_net_loss  AS loss_amount
    FROM web_agg wa
    JOIN customer_demographics cd2 ON wa.wr_refunded_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON wa.wr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN time_dim t2 ON wa.wr_returned_time_sk = t2.t_time_sk
    WHERE cd2.cd_gender IN ('M', 'F')
      AND t2.t_meal_time IN ('breakfast', 'lunch', 'dinner')
  )
SELECT
  gender,
  meal_time,
  SUM(loss_amount) AS combined_loss,
  AVG(loss_amount) AS avg_loss,
  (SELECT AVG(sr_net_loss) FROM store_returns) AS overall_avg_store_loss
FROM combined
GROUP BY gender, meal_time
HAVING SUM(loss_amount) > 100
ORDER BY combined_loss DESC
LIMIT 100
