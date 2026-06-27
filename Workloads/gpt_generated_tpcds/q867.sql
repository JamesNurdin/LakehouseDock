WITH sales_agg AS (
  SELECT
    d_sold.d_year AS year,
    d_sold.d_month_seq AS month,
    i.i_category AS category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d_sold.d_date >= DATE '2021-01-01' AND d_sold.d_date < DATE '2022-01-01'
  GROUP BY d_sold.d_year, d_sold.d_month_seq, i.i_category
),
returns_agg AS (
  SELECT
    d_ret.d_year AS year,
    d_ret.d_month_seq AS month,
    i.i_category AS category,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d_ret.d_date >= DATE '2021-01-01' AND d_ret.d_date < DATE '2022-01-01'
  GROUP BY d_ret.d_year, d_ret.d_month_seq, i.i_category
)
SELECT
  s.year,
  s.month,
  s.category,
  s.total_sales,
  s.total_profit,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
  s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.year = r.year
  AND s.month = r.month
  AND s.category = r.category
ORDER BY net_profit DESC
LIMIT 10
