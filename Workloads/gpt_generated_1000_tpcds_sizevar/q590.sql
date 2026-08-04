WITH
  common_cdemo AS (
    SELECT cr.cr_refunded_cdemo_sk AS cd_demo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
    INTERSECT
    SELECT wr.wr_refunded_cdemo_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
  ),
  sr_sample AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
  ),
  joined AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_return_amt,
      sr.sr_net_loss,
      cr.cr_return_amount,
      cr.cr_net_loss AS cr_net_loss,
      wr.wr_return_amt,
      d.d_year,
      t.t_meal_time,
      cd.cd_gender
    FROM sr_sample sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN common_cdemo ccd ON cd.cd_demo_sk = ccd.cd_demo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2000
      AND t.t_meal_time = 'lunch'
      AND cd.cd_gender = 'F'
      AND cr.cr_return_amount > 50
      AND wr.wr_fee < 20
  )
SELECT
  joined.sr_store_sk,
  joined.d_year,
  joined.t_meal_time,
  joined.cd_gender,
  joined.sr_return_amt,
  joined.sr_net_loss,
  joined.cr_return_amount,
  joined.wr_return_amt,
  (
    SELECT SUM(wr2.wr_return_amt)
    FROM web_returns wr2
    WHERE wr2.wr_returned_date_sk = joined.sr_returned_date_sk
  ) AS total_web_return_amt_by_date,
  RANK() OVER (PARTITION BY joined.sr_store_sk ORDER BY joined.sr_return_amt DESC) AS rank_by_store_return_amt,
  SUM(joined.sr_return_amt) OVER (
    PARTITION BY joined.sr_store_sk
    ORDER BY joined.sr_returned_date_sk
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS sum_last_3_returns
FROM joined
ORDER BY joined.sr_store_sk, rank_by_store_return_amt
LIMIT 100
