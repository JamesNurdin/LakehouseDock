WITH sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(ss.ss_quantity) AS total_qty
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
),
returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    SUM(sr.sr_net_loss) AS total_returns,
    SUM(sr.sr_return_quantity) AS total_qty_returned
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand
)
SELECT
  s.d_year,
  s.d_month_seq,
  s.i_category,
  s.i_brand,
  s.total_sales,
  COALESCE(r.total_returns, 0) AS total_returns,
  s.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
  s.total_profit,
  s.distinct_customers,
  s.total_qty,
  COALESCE(r.total_qty_returned, 0) AS total_qty_returned
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
 AND s.i_category = r.i_category
 AND s.i_brand = r.i_brand
ORDER BY s.d_year, s.d_month_seq, s.total_sales DESC
LIMIT 100
