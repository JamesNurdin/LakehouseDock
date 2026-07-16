WITH sales AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_ext_sales_price) AS sales_ext_price,
    SUM(cs.cs_quantity) AS sales_qty,
    SUM(cs.cs_net_profit) AS sales_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq
),
store_sales_agg AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS sales_ext_price,
    SUM(ss.ss_quantity) AS sales_qty,
    SUM(ss.ss_net_profit) AS sales_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq
),
web_sales_agg AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_ext_sales_price) AS sales_ext_price,
    SUM(ws.ws_quantity) AS sales_qty,
    SUM(ws.ws_net_profit) AS sales_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq
),
sales_union AS (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
),
sales_agg AS (
  SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    d_year,
    d_month_seq,
    SUM(sales_ext_price) AS total_sales,
    SUM(sales_qty) AS total_qty,
    SUM(sales_profit) AS total_profit
  FROM sales_union
  GROUP BY i_item_sk, i_item_id, i_product_name, d_year, d_month_seq
),
returns AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_return_quantity) AS return_qty,
    SUM(cr.cr_net_loss) AS return_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq
  UNION ALL
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    SUM(sr.sr_return_quantity) AS return_qty,
    SUM(sr.sr_net_loss) AS return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq
  UNION ALL
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    SUM(wr.wr_return_quantity) AS return_qty,
    SUM(wr.wr_net_loss) AS return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq
),
returns_agg AS (
  SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    d_year,
    d_month_seq,
    SUM(return_qty) AS total_return_qty,
    SUM(return_loss) AS total_return_loss
  FROM returns
  GROUP BY i_item_sk, i_item_id, i_product_name, d_year, d_month_seq
)
SELECT
  s.d_year,
  s.d_month_seq,
  s.i_item_id,
  s.i_product_name,
  s.total_sales,
  s.total_qty,
  s.total_profit,
  COALESCE(r.total_return_qty, 0) AS total_return_qty,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_contribution,
  CASE WHEN s.total_sales > 0 THEN (s.total_profit - COALESCE(r.total_return_loss, 0)) / s.total_sales ELSE NULL END AS profit_margin,
  CASE WHEN s.total_qty > 0 THEN COALESCE(r.total_return_qty, 0) * 1.0 / s.total_qty ELSE NULL END AS return_rate,
  DENSE_RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY (s.total_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank,
  AVG(s.total_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.i_item_id ORDER BY s.d_year, s.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_rolling_avg_contribution
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.i_item_sk = r.i_item_sk
  AND s.d_year = r.d_year
  AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year DESC, s.d_month_seq DESC, net_contribution DESC
LIMIT 100
