WITH sales_agg AS (
  SELECT d.d_year AS year,
         i.i_category AS category,
         SUM(s.sales_amount) AS total_sales,
         SUM(s.profit_amount) AS total_profit
  FROM (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_ext_sales_price AS sales_amount,
           ss.ss_net_profit AS profit_amount
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_ext_sales_price,
           ws.ws_net_profit
    FROM web_sales ws
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_ext_sales_price,
           cs.cs_net_profit
    FROM catalog_sales cs
  ) s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category
),
returns_agg AS (
  SELECT d.d_year AS year,
         i.i_category AS category,
         SUM(r.return_amount) AS total_return_amount,
         SUM(r.loss_amount) AS total_return_loss
  FROM (
    SELECT sr.sr_returned_date_sk AS date_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_return_amt AS return_amount,
           sr.sr_net_loss AS loss_amount
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_amt,
           wr.wr_net_loss
    FROM web_returns wr
    UNION ALL
    SELECT cr.cr_returned_date_sk,
           cr.cr_item_sk,
           cr.cr_return_amount,
           cr.cr_net_loss
    FROM catalog_returns cr
  ) r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  JOIN item i ON r.item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category
)
SELECT s.year,
       s.category,
       s.total_sales,
       COALESCE(r.total_return_amount, 0) AS total_returns,
       s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.year = r.year AND s.category = r.category
ORDER BY s.year, s.category
