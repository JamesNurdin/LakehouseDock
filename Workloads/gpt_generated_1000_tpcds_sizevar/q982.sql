WITH
  sales_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_cdemo_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM
      store_sales ss TABLESAMPLE BERNOULLI (10)
    WHERE
      ss.ss_wholesale_cost > 30
    GROUP BY
      ss.ss_store_sk,
      ss.ss_cdemo_sk
  ),
  excluded_tickets AS (
    SELECT sr.sr_ticket_number AS ticket
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 5
    EXCEPT
    SELECT wr.wr_order_number AS ticket
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 2
  )
SELECT
  s.s_store_name,
  cd.cd_gender,
  cd.cd_marital_status,
  sa.total_sales,
  sa.total_profit,
  COUNT(sr.sr_ticket_number) AS return_cnt,
  SUM(sr.sr_net_loss) AS total_return_loss,
  SUM(wr.wr_return_amt) AS web_return_amt
FROM
  sales_agg sa
  JOIN store s ON sa.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON sa.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_ticket_number NOT IN (SELECT ticket FROM excluded_tickets)
  LEFT JOIN web_returns wr
    ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
WHERE
  s.s_state = 'CA'
  AND cd.cd_gender = 'M'
  AND s.s_gmt_offset = -5.00
  AND wr.wr_return_ship_cost < 100
  AND EXISTS (
    SELECT 1
    FROM web_returns w2
    WHERE w2.wr_returning_cdemo_sk = cd.cd_demo_sk
  )
GROUP BY
  s.s_store_name,
  cd.cd_gender,
  cd.cd_marital_status,
  sa.total_sales,
  sa.total_profit
ORDER BY
  sa.total_sales DESC
LIMIT 100
