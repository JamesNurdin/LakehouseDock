WITH
  store_sales_cte AS (
    SELECT
      cd.cd_gender,
      cd.cd_education_status,
      td.t_hour,
      SUM(ss.ss_net_profit) AS sales_profit,
      SUM(ss.ss_net_paid)   AS sales_paid
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status, td.t_hour
  ),
  store_returns_cte AS (
    SELECT
      cd.cd_gender,
      cd.cd_education_status,
      td.t_hour,
      SUM(sr.sr_net_loss) AS returns_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status, td.t_hour
  ),
  catalog_sales_cte AS (
    SELECT
      cd.cd_gender,
      cd.cd_education_status,
      td.t_hour,
      SUM(cs.cs_net_profit) AS sales_profit,
      SUM(cs.cs_net_paid)   AS sales_paid
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status, td.t_hour
  ),
  catalog_returns_cte AS (
    SELECT
      cd.cd_gender,
      cd.cd_education_status,
      td.t_hour,
      SUM(cr.cr_net_loss) AS returns_loss
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status, td.t_hour
  ),
  web_sales_cte AS (
    SELECT
      cd.cd_gender,
      cd.cd_education_status,
      td.t_hour,
      SUM(ws.ws_net_profit) AS sales_profit,
      SUM(ws.ws_net_paid)   AS sales_paid
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status, td.t_hour
  ),
  web_returns_cte AS (
    SELECT
      cd.cd_gender,
      cd.cd_education_status,
      td.t_hour,
      SUM(wr.wr_net_loss) AS returns_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_education_status, td.t_hour
  ),
  combined_sales AS (
    SELECT
      cd_gender,
      cd_education_status,
      t_hour,
      SUM(sales_profit) AS total_sales_profit,
      SUM(sales_paid)   AS total_sales_paid
    FROM (
      SELECT cd_gender, cd_education_status, t_hour, sales_profit, sales_paid FROM store_sales_cte
      UNION ALL
      SELECT cd_gender, cd_education_status, t_hour, sales_profit, sales_paid FROM catalog_sales_cte
      UNION ALL
      SELECT cd_gender, cd_education_status, t_hour, sales_profit, sales_paid FROM web_sales_cte
    ) s
    GROUP BY cd_gender, cd_education_status, t_hour
  ),
  combined_returns AS (
    SELECT
      cd_gender,
      cd_education_status,
      t_hour,
      SUM(returns_loss) AS total_returns_loss
    FROM (
      SELECT cd_gender, cd_education_status, t_hour, returns_loss FROM store_returns_cte
      UNION ALL
      SELECT cd_gender, cd_education_status, t_hour, returns_loss FROM catalog_returns_cte
      UNION ALL
      SELECT cd_gender, cd_education_status, t_hour, returns_loss FROM web_returns_cte
    ) r
    GROUP BY cd_gender, cd_education_status, t_hour
  )
SELECT
  cs.cd_gender,
  cs.cd_education_status,
  cs.t_hour,
  cs.total_sales_profit - COALESCE(cr.total_returns_loss, 0) AS net_profit,
  cs.total_sales_paid,
  COALESCE(cr.total_returns_loss, 0)               AS total_returns_loss
FROM combined_sales cs
LEFT JOIN combined_returns cr
  ON cs.cd_gender = cr.cd_gender
 AND cs.cd_education_status = cr.cd_education_status
 AND cs.t_hour = cr.t_hour
ORDER BY net_profit DESC
LIMIT 10
