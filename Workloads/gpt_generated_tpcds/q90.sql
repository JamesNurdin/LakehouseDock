WITH
    store_sales_agg AS (
        SELECT d.d_year AS year,
               cd.cd_gender AS gender,
               SUM(ss.ss_net_profit) AS sales_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        GROUP BY d.d_year, cd.cd_gender
    ),
    store_returns_agg AS (
        SELECT d.d_year AS year,
               cd.cd_gender AS gender,
               SUM(sr.sr_net_loss) AS return_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        GROUP BY d.d_year, cd.cd_gender
    ),
    catalog_sales_agg AS (
        SELECT d.d_year AS year,
               cd.cd_gender AS gender,
               SUM(cs.cs_net_profit) AS sales_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        GROUP BY d.d_year, cd.cd_gender
    ),
    catalog_returns_agg AS (
        SELECT d.d_year AS year,
               cd.cd_gender AS gender,
               SUM(cr.cr_net_loss) AS return_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        GROUP BY d.d_year, cd.cd_gender
    ),
    web_sales_agg AS (
        SELECT d.d_year AS year,
               cd.cd_gender AS gender,
               SUM(ws.ws_net_profit) AS sales_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        GROUP BY d.d_year, cd.cd_gender
    ),
    web_returns_agg AS (
        SELECT d.d_year AS year,
               cd.cd_gender AS gender,
               SUM(wr.wr_net_loss) AS return_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        GROUP BY d.d_year, cd.cd_gender
    ),
    store_combined AS (
        SELECT ss.year,
               ss.gender,
               ss.sales_profit,
               COALESCE(sr.return_loss, 0) AS return_loss,
               ss.sales_profit - COALESCE(sr.return_loss, 0) AS net_profit,
               'store' AS channel
        FROM store_sales_agg ss
        LEFT JOIN store_returns_agg sr
          ON ss.year = sr.year AND ss.gender = sr.gender
    ),
    catalog_combined AS (
        SELECT cs.year,
               cs.gender,
               cs.sales_profit,
               COALESCE(cr.return_loss, 0) AS return_loss,
               cs.sales_profit - COALESCE(cr.return_loss, 0) AS net_profit,
               'catalog' AS channel
        FROM catalog_sales_agg cs
        LEFT JOIN catalog_returns_agg cr
          ON cs.year = cr.year AND cs.gender = cr.gender
    ),
    web_combined AS (
        SELECT ws.year,
               ws.gender,
               ws.sales_profit,
               COALESCE(wr.return_loss, 0) AS return_loss,
               ws.sales_profit - COALESCE(wr.return_loss, 0) AS net_profit,
               'web' AS channel
        FROM web_sales_agg ws
        LEFT JOIN web_returns_agg wr
          ON ws.year = wr.year AND ws.gender = wr.gender
    )
SELECT year,
       gender,
       channel,
       sales_profit,
       return_loss,
       net_profit
FROM (
    SELECT year,
           gender,
           sales_profit,
           return_loss,
           net_profit,
           channel
    FROM store_combined
    UNION ALL
    SELECT year,
           gender,
           sales_profit,
           return_loss,
           net_profit,
           channel
    FROM catalog_combined
    UNION ALL
    SELECT year,
           gender,
           sales_profit,
           return_loss,
           net_profit,
           channel
    FROM web_combined
) AS combined
ORDER BY year DESC,
         gender,
         channel
