/*
  Net revenue by hour of day for United‑States‑born customers across the three sales channels.
  The query aggregates net profit from sales and net loss from returns, then computes
  net revenue per channel and overall.
*/
WITH
  /* Sales for US‑born customers */
  catalog_sales_us AS (
    SELECT
      cs.cs_sold_time_sk,
      cs.cs_net_profit
    FROM
      catalog_sales cs
      JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    WHERE
      cu.c_birth_country = 'United States'
  ),
  store_sales_us AS (
    SELECT
      ss.ss_sold_time_sk,
      ss.ss_net_profit
    FROM
      store_sales ss
      JOIN customer cu ON ss.ss_customer_sk = cu.c_customer_sk
    WHERE
      cu.c_birth_country = 'United States'
  ),
  web_sales_us AS (
    SELECT
      ws.ws_sold_time_sk,
      ws.ws_net_profit
    FROM
      web_sales ws
      JOIN customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
    WHERE
      cu.c_birth_country = 'United States'
  ),

  /* Returns for US‑born customers */
  catalog_returns_us AS (
    SELECT
      cr.cr_returned_time_sk,
      cr.cr_net_loss
    FROM
      catalog_returns cr
      JOIN customer cu ON cr.cr_refunded_customer_sk = cu.c_customer_sk
    WHERE
      cu.c_birth_country = 'United States'
  ),
  store_returns_us AS (
    SELECT
      sr.sr_return_time_sk,
      sr.sr_net_loss
    FROM
      store_returns sr
      JOIN customer cu ON sr.sr_customer_sk = cu.c_customer_sk
    WHERE
      cu.c_birth_country = 'United States'
  ),
  web_returns_us AS (
    SELECT
      wr.wr_returned_time_sk,
      wr.wr_net_loss
    FROM
      web_returns wr
      JOIN customer cu ON wr.wr_refunded_customer_sk = cu.c_customer_sk
    WHERE
      cu.c_birth_country = 'United States'
  ),

  /* Aggregate sales profit per hour */
  sales_agg AS (
    SELECT
      td.t_hour,
      SUM(cs.cs_net_profit)   AS catalog_net_profit,
      SUM(ss.ss_net_profit)   AS store_net_profit,
      SUM(ws.ws_net_profit)   AS web_net_profit
    FROM
      time_dim td
      LEFT JOIN catalog_sales_us cs ON cs.cs_sold_time_sk = td.t_time_sk
      LEFT JOIN store_sales_us   ss ON ss.ss_sold_time_sk = td.t_time_sk
      LEFT JOIN web_sales_us     ws ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY
      td.t_hour
  ),

  /* Aggregate returns loss per hour */
  returns_agg AS (
    SELECT
      td.t_hour,
      SUM(cr.cr_net_loss)   AS catalog_net_loss,
      SUM(sr.sr_net_loss)   AS store_net_loss,
      SUM(wr.wr_net_loss)   AS web_net_loss
    FROM
      time_dim td
      LEFT JOIN catalog_returns_us cr ON cr.cr_returned_time_sk = td.t_time_sk
      LEFT JOIN store_returns_us   sr ON sr.sr_return_time_sk = td.t_time_sk
      LEFT JOIN web_returns_us     wr ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY
      td.t_hour
  )
SELECT
  COALESCE(sa.t_hour, ra.t_hour)                               AS hour_of_day,
  sa.catalog_net_profit,
  ra.catalog_net_loss,
  sa.store_net_profit,
  ra.store_net_loss,
  sa.web_net_profit,
  ra.web_net_loss,
  COALESCE(sa.catalog_net_profit, 0) - COALESCE(ra.catalog_net_loss, 0) AS catalog_net_revenue,
  COALESCE(sa.store_net_profit, 0)   - COALESCE(ra.store_net_loss, 0)   AS store_net_revenue,
  COALESCE(sa.web_net_profit, 0)    - COALESCE(ra.web_net_loss, 0)    AS web_net_revenue,
  COALESCE(sa.catalog_net_profit, 0) - COALESCE(ra.catalog_net_loss, 0)
  + COALESCE(sa.store_net_profit, 0) - COALESCE(ra.store_net_loss, 0)
  + COALESCE(sa.web_net_profit, 0)   - COALESCE(ra.web_net_loss, 0)   AS total_net_revenue
FROM
  sales_agg  sa
  FULL OUTER JOIN returns_agg ra ON sa.t_hour = ra.t_hour
ORDER BY
  hour_of_day
