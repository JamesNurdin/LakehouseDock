WITH sales_agg AS (
  SELECT ss.ss_item_sk AS item_sk,
         d.d_year AS year,
         SUM(ss.ss_quantity) AS quantity,
         SUM(ss.ss_net_paid) AS net_paid,
         SUM(ss.ss_net_profit) AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY ss.ss_item_sk, d.d_year
  UNION ALL
  SELECT cs.cs_item_sk,
         d.d_year,
         SUM(cs.cs_quantity),
         SUM(cs.cs_net_paid),
         SUM(cs.cs_net_profit)
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  GROUP BY cs.cs_item_sk, d.d_year
  UNION ALL
  SELECT ws.ws_item_sk,
         d.d_year,
         SUM(ws.ws_quantity),
         SUM(ws.ws_net_paid),
         SUM(ws.ws_net_profit)
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY ws.ws_item_sk, d.d_year
),
sales_total AS (
  SELECT item_sk,
         year,
         SUM(quantity) AS total_quantity,
         SUM(net_paid) AS total_net_paid,
         SUM(net_profit) AS total_net_profit
  FROM sales_agg
  GROUP BY item_sk, year
),
returns_agg AS (
  SELECT sr.sr_item_sk AS item_sk,
         d.d_year AS year,
         SUM(sr.sr_return_quantity) AS return_quantity,
         SUM(sr.sr_return_amt) AS return_amount,
         SUM(sr.sr_net_loss) AS return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  GROUP BY sr.sr_item_sk, d.d_year
  UNION ALL
  SELECT cr.cr_item_sk,
         d.d_year,
         SUM(cr.cr_return_quantity),
         SUM(cr.cr_return_amount),
         SUM(cr.cr_net_loss)
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  GROUP BY cr.cr_item_sk, d.d_year
  UNION ALL
  SELECT wr.wr_item_sk,
         d.d_year,
         SUM(wr.wr_return_quantity),
         SUM(wr.wr_return_amt),
         SUM(wr.wr_net_loss)
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY wr.wr_item_sk, d.d_year
),
returns_total AS (
  SELECT item_sk,
         year,
         SUM(return_quantity) AS total_return_quantity,
         SUM(return_amount) AS total_return_amount,
         SUM(return_loss) AS total_return_loss
  FROM returns_agg
  GROUP BY item_sk, year
),
combined AS (
  SELECT s.item_sk,
         s.year,
         s.total_quantity,
         s.total_net_paid,
         s.total_net_profit,
         COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
         COALESCE(r.total_return_amount, 0) AS total_return_amount,
         COALESCE(r.total_return_loss, 0) AS total_return_loss
  FROM sales_total s
  LEFT JOIN returns_total r
    ON s.item_sk = r.item_sk AND s.year = r.year
),
ranked AS (
  SELECT d.d_year AS year,
         i.i_item_id,
         i.i_product_name,
         c.total_quantity,
         c.total_net_paid,
         c.total_net_profit,
         c.total_return_quantity,
         c.total_return_amount,
         c.total_return_loss,
         (c.total_net_profit - c.total_return_loss) AS net_profit_after_returns,
         ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY (c.total_net_profit - c.total_return_loss) DESC) AS rn
  FROM combined c
  JOIN item i ON c.item_sk = i.i_item_sk
  JOIN date_dim d ON c.year = d.d_year
  WHERE d.d_year BETWEEN 1999 AND 2002
)
SELECT year,
       i_item_id,
       i_product_name,
       total_quantity,
       total_net_paid,
       total_net_profit,
       total_return_quantity,
       total_return_amount,
       total_return_loss,
       net_profit_after_returns,
       rn AS profit_rank
FROM ranked
WHERE rn <= 5
ORDER BY year, profit_rank
