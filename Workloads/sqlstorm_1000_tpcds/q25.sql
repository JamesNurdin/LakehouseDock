WITH
catalog_sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(cs.cs_net_profit) AS sales_net_profit,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    SUM(cs.cs_quantity) AS sales_quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND i.i_current_price > 20
  GROUP BY d.d_year, i.i_category
),
store_sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(ss.ss_net_profit) AS sales_net_profit,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    SUM(ss.ss_quantity) AS sales_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND i.i_current_price > 20
  GROUP BY d.d_year, i.i_category
),
web_sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(ws.ws_net_profit) AS sales_net_profit,
    SUM(ws.ws_ext_sales_price) AS sales_amount,
    SUM(ws.ws_quantity) AS sales_quantity
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND i.i_current_price > 20
  GROUP BY d.d_year, i.i_category
),
catalog_returns_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(cr.cr_net_loss) AS returns_net_loss,
    SUM(cr.cr_return_quantity) AS return_quantity,
    SUM(cr.cr_return_amount) AS return_amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND i.i_current_price > 20
  GROUP BY d.d_year, i.i_category
),
store_returns_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(sr.sr_net_loss) AS returns_net_loss,
    SUM(sr.sr_return_quantity) AS return_quantity,
    SUM(sr.sr_return_amt) AS return_amount
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND i.i_current_price > 20
  GROUP BY d.d_year, i.i_category
),
web_returns_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(wr.wr_net_loss) AS returns_net_loss,
    SUM(wr.wr_return_quantity) AS return_quantity,
    SUM(wr.wr_return_amt) AS return_amount
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
    AND i.i_current_price > 20
  GROUP BY d.d_year, i.i_category
),
sales_totals AS (
  SELECT
    d_year,
    i_category,
    SUM(sales_net_profit) AS total_sales_net_profit,
    SUM(sales_amount) AS total_sales_amount,
    SUM(sales_quantity) AS total_sales_quantity
  FROM (
    SELECT d_year, i_category, sales_net_profit, sales_amount, sales_quantity FROM catalog_sales_agg
    UNION ALL
    SELECT d_year, i_category, sales_net_profit, sales_amount, sales_quantity FROM store_sales_agg
    UNION ALL
    SELECT d_year, i_category, sales_net_profit, sales_amount, sales_quantity FROM web_sales_agg
  ) s
  GROUP BY d_year, i_category
),
returns_totals AS (
  SELECT
    d_year,
    i_category,
    SUM(returns_net_loss) AS total_returns_net_loss,
    SUM(return_quantity) AS total_return_quantity,
    SUM(return_amount) AS total_return_amount
  FROM (
    SELECT d_year, i_category, returns_net_loss, return_quantity, return_amount FROM catalog_returns_agg
    UNION ALL
    SELECT d_year, i_category, returns_net_loss, return_quantity, return_amount FROM store_returns_agg
    UNION ALL
    SELECT d_year, i_category, returns_net_loss, return_quantity, return_amount FROM web_returns_agg
  ) r
  GROUP BY d_year, i_category
),
combined_sales AS (
  SELECT
    s.d_year,
    s.i_category,
    s.total_sales_net_profit - COALESCE(r.total_returns_net_loss, 0) AS net_profit,
    s.total_sales_amount,
    s.total_sales_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount
  FROM sales_totals s
  LEFT JOIN returns_totals r
    ON s.d_year = r.d_year AND s.i_category = r.i_category
),
ranked_categories AS (
  SELECT
    d_year,
    i_category,
    net_profit,
    total_sales_amount,
    total_sales_quantity,
    total_return_quantity,
    total_return_amount,
    RANK() OVER (PARTITION BY d_year ORDER BY net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales_amount DESC) AS sales_rank,
    LAG(net_profit) OVER (PARTITION BY i_category ORDER BY d_year) AS prev_year_profit,
    net_profit - COALESCE(LAG(net_profit) OVER (PARTITION BY i_category ORDER BY d_year), 0) AS profit_delta,
    AVG(net_profit) OVER (PARTITION BY d_year) AS avg_yearly_profit,
    SUM(net_profit) OVER (PARTITION BY d_year) AS sum_yearly_profit
  FROM combined_sales
)
SELECT
  d_year,
  i_category,
  net_profit,
  total_sales_amount,
  total_sales_quantity,
  total_return_quantity,
  total_return_amount,
  profit_rank,
  sales_rank,
  profit_delta,
  avg_yearly_profit,
  sum_yearly_profit
FROM ranked_categories
WHERE profit_rank <= 5
ORDER BY d_year, profit_rank
