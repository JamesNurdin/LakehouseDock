WITH
  sales_data AS (
    SELECT
      ss.ss_store_sk,
      s.s_store_id,
      s.s_market_id,
      cd_sales.cd_gender AS sales_gender,
      SUM(ss.ss_net_paid) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd_sales
      ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    GROUP BY ss.ss_store_sk, s.s_store_id, s.s_market_id, cd_sales.cd_gender
  ),
  returns_data AS (
    SELECT
      cd_refunded.cd_gender AS refunded_gender,
      cd_returning.cd_gender AS returning_gender,
      r.r_reason_desc,
      SUM(cr.cr_net_loss) AS total_net_loss,
      SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_refunded
      ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning
      ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    GROUP BY cd_refunded.cd_gender, cd_returning.cd_gender, r.r_reason_desc
  )
SELECT
  sd.s_store_id,
  sd.s_market_id,
  sd.sales_gender,
  rd.refunded_gender,
  rd.returning_gender,
  rd.r_reason_desc,
  sd.total_sales,
  sd.total_profit,
  rd.total_net_loss,
  rd.total_return_amount
FROM sales_data sd
JOIN returns_data rd
  ON sd.sales_gender = rd.refunded_gender
ORDER BY sd.s_market_id, sd.s_store_id, sd.total_sales DESC
LIMIT 100
