WITH
  -- Aggregate store sales by year, gender, marital status and the unique sale identifier
  store_sales_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      cd.cd_marital_status AS marital_status,
      ss.ss_ticket_number,
      ss.ss_item_sk,
      SUM(ss.ss_net_profit) AS sales_profit,
      SUM(ss.ss_net_paid)   AS sales_amount
    FROM store_sales ss
    JOIN date_dim d       ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c       ON ss.ss_customer_sk   = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status, ss.ss_ticket_number, ss.ss_item_sk
  ),
  -- Aggregate store returns by the same identifiers
  store_returns_agg AS (
    SELECT
      sr.sr_ticket_number AS ticket_number,
      sr.sr_item_sk      AS item_sk,
      SUM(sr.sr_net_loss)          AS returns_loss,
      SUM(sr.sr_return_amt_inc_tax) AS returns_amount
    FROM store_returns sr
    GROUP BY sr.sr_ticket_number, sr.sr_item_sk
  ),
  -- Combine sales and returns for the store channel
  store_data AS (
    SELECT
      ss.year,
      ss.gender,
      ss.marital_status,
      ss.sales_profit,
      ss.sales_amount,
      COALESCE(sr.returns_loss, 0)   AS returns_loss,
      COALESCE(sr.returns_amount, 0) AS returns_amount
    FROM store_sales_agg ss
    LEFT JOIN store_returns_agg sr
      ON ss.ss_ticket_number = sr.ticket_number
     AND ss.ss_item_sk       = sr.item_sk
  ),

  -- Aggregate web sales
  web_sales_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      cd.cd_marital_status AS marital_status,
      ws.ws_order_number,
      ws.ws_item_sk,
      SUM(ws.ws_net_profit) AS sales_profit,
      SUM(ws.ws_net_paid)   AS sales_amount
    FROM web_sales ws
    JOIN date_dim d       ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c       ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status, ws.ws_order_number, ws.ws_item_sk
  ),
  -- Aggregate web returns
  web_returns_agg AS (
    SELECT
      wr.wr_order_number AS order_number,
      wr.wr_item_sk      AS item_sk,
      SUM(wr.wr_net_loss)          AS returns_loss,
      SUM(wr.wr_return_amt_inc_tax) AS returns_amount
    FROM web_returns wr
    GROUP BY wr.wr_order_number, wr.wr_item_sk
  ),
  -- Combine sales and returns for the web channel
  web_data AS (
    SELECT
      ws.year,
      ws.gender,
      ws.marital_status,
      ws.sales_profit,
      ws.sales_amount,
      COALESCE(wr.returns_loss, 0)   AS returns_loss,
      COALESCE(wr.returns_amount, 0) AS returns_amount
    FROM web_sales_agg ws
    LEFT JOIN web_returns_agg wr
      ON ws.ws_order_number = wr.order_number
     AND ws.ws_item_sk       = wr.item_sk
  ),

  -- Aggregate catalog sales
  catalog_sales_agg AS (
    SELECT
      d.d_year AS year,
      cd.cd_gender AS gender,
      cd.cd_marital_status AS marital_status,
      cs.cs_order_number,
      cs.cs_item_sk,
      SUM(cs.cs_net_profit) AS sales_profit,
      SUM(cs.cs_net_paid)   AS sales_amount
    FROM catalog_sales cs
    JOIN date_dim d       ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c       ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status, cs.cs_order_number, cs.cs_item_sk
  ),
  -- Aggregate catalog returns
  catalog_returns_agg AS (
    SELECT
      cr.cr_order_number AS order_number,
      cr.cr_item_sk      AS item_sk,
      SUM(cr.cr_net_loss)          AS returns_loss,
      SUM(cr.cr_return_amt_inc_tax) AS returns_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number, cr.cr_item_sk
  ),
  -- Combine sales and returns for the catalog channel
  catalog_data AS (
    SELECT
      cs.year,
      cs.gender,
      cs.marital_status,
      cs.sales_profit,
      cs.sales_amount,
      COALESCE(cr.returns_loss, 0)   AS returns_loss,
      COALESCE(cr.returns_amount, 0) AS returns_amount
    FROM catalog_sales_agg cs
    LEFT JOIN catalog_returns_agg cr
      ON cs.cs_order_number = cr.order_number
     AND cs.cs_item_sk       = cr.item_sk
  ),

  -- Union the three channels
  combined AS (
    SELECT 'Store'   AS channel, year, gender, marital_status, sales_profit, sales_amount, returns_loss, returns_amount,
           (sales_profit - returns_loss) AS net_profit
    FROM store_data
    UNION ALL
    SELECT 'Web'     AS channel, year, gender, marital_status, sales_profit, sales_amount, returns_loss, returns_amount,
           (sales_profit - returns_loss) AS net_profit
    FROM web_data
    UNION ALL
    SELECT 'Catalog' AS channel, year, gender, marital_status, sales_profit, sales_amount, returns_loss, returns_amount,
           (sales_profit - returns_loss) AS net_profit
    FROM catalog_data
  )
SELECT
  channel,
  year,
  gender,
  marital_status,
  sales_profit,
  sales_amount,
  returns_loss,
  returns_amount,
  net_profit,
  SUM(net_profit) OVER (PARTITION BY year)               AS total_year_profit,
  RANK()          OVER (PARTITION BY year ORDER BY net_profit DESC) AS profit_rank
FROM combined
ORDER BY year, profit_rank
