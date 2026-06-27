/*
  Hour‑by‑hour performance overview:
  - Total sales (net paid & profit) from store_sales
  - Return counts and net‑loss amounts from store, catalog, and web returns
  - Net profit after accounting for all return losses
*/
WITH sales_by_hour AS (
    SELECT td.t_hour,
           COUNT(*) AS sales_count,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
store_returns_by_hour AS (
    SELECT td.t_hour,
           COUNT(*) AS store_return_count,
           SUM(sr.sr_net_loss) AS store_return_net_loss,
           SUM(sr.sr_return_amt) AS store_return_amount
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
catalog_returns_by_hour AS (
    SELECT td.t_hour,
           COUNT(*) AS catalog_return_count,
           SUM(cr.cr_net_loss) AS catalog_return_net_loss,
           SUM(cr.cr_return_amount) AS catalog_return_amount
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
web_returns_by_hour AS (
    SELECT td.t_hour,
           COUNT(*) AS web_return_count,
           SUM(wr.wr_net_loss) AS web_return_net_loss,
           SUM(wr.wr_return_amt) AS web_return_amount
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_hour
)
SELECT COALESCE(sales.t_hour,
               store_returns.t_hour,
               catalog_returns.t_hour,
               web_returns.t_hour) AS hour_of_day,
       COALESCE(sales.sales_count, 0)               AS sales_count,
       COALESCE(sales.total_net_paid, 0)            AS total_net_paid,
       COALESCE(sales.total_net_profit, 0)          AS total_net_profit,
       COALESCE(store_returns.store_return_count, 0)   AS store_return_count,
       COALESCE(store_returns.store_return_net_loss, 0) AS store_return_net_loss,
       COALESCE(catalog_returns.catalog_return_count, 0)   AS catalog_return_count,
       COALESCE(catalog_returns.catalog_return_net_loss, 0) AS catalog_return_net_loss,
       COALESCE(web_returns.web_return_count, 0)         AS web_return_count,
       COALESCE(web_returns.web_return_net_loss, 0)      AS web_return_net_loss,
       (COALESCE(store_returns.store_return_net_loss, 0) +
        COALESCE(catalog_returns.catalog_return_net_loss, 0) +
        COALESCE(web_returns.web_return_net_loss, 0))       AS total_return_net_loss,
       (COALESCE(sales.total_net_profit, 0) -
        (COALESCE(store_returns.store_return_net_loss, 0) +
         COALESCE(catalog_returns.catalog_return_net_loss, 0) +
         COALESCE(web_returns.web_return_net_loss, 0))) AS net_profit_after_returns
FROM sales_by_hour sales
FULL OUTER JOIN store_returns_by_hour store_returns
    ON sales.t_hour = store_returns.t_hour
FULL OUTER JOIN catalog_returns_by_hour catalog_returns
    ON COALESCE(sales.t_hour, store_returns.t_hour) = catalog_returns.t_hour
FULL OUTER JOIN web_returns_by_hour web_returns
    ON COALESCE(sales.t_hour, store_returns.t_hour, catalog_returns.t_hour) = web_returns.t_hour
ORDER BY hour_of_day
