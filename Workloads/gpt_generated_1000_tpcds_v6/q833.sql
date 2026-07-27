WITH store_part AS (
   SELECT
      cd.cd_gender AS gender,
      SUM(sr.sr_net_loss) AS total_net_loss,
      'store' AS source
   FROM store_returns sr
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
   WHERE cd.cd_credit_rating = 'High Risk'
     AND td.t_meal_time = 'dinner'
     AND EXISTS (
         SELECT 1
         FROM web_returns wr
         WHERE wr.wr_refunded_cdemo_sk = sr.sr_cdemo_sk
           AND wr.wr_returned_time_sk = sr.sr_return_time_sk
     )
   GROUP BY cd.cd_gender
),
web_part AS (
   SELECT
      cd.cd_gender AS gender,
      SUM(wr.wr_net_loss) AS total_net_loss,
      'web' AS source
   FROM web_returns wr
   JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
   WHERE cd.cd_credit_rating = 'Low Risk'
     AND td.t_meal_time = 'lunch'
   GROUP BY cd.cd_gender
)
SELECT gender,
       total_net_loss,
       source
FROM store_part
UNION ALL
SELECT gender,
       total_net_loss,
       source
FROM web_part
ORDER BY total_net_loss DESC
LIMIT 100
