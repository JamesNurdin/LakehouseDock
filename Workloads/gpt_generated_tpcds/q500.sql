WITH sales_agg AS (
  SELECT
    d.d_year AS sales_year,
    d.d_moy AS sales_month,
    c.c_birth_year AS birth_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    COUNT(DISTINCT c.c_customer_sk) AS cust_cnt
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  GROUP BY d.d_year, d.d_moy, c.c_birth_year
),
returns_agg AS (
  SELECT
    d.d_year AS return_year,
    d.d_moy AS return_month,
    c.c_birth_year AS birth_year,
    SUM(wr.wr_return_amt_inc_tax) AS total_returns,
    SUM(wr.wr_net_loss) AS total_loss,
    COUNT(DISTINCT wr.wr_order_number) AS return_order_cnt
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
  GROUP BY d.d_year, d.d_moy, c.c_birth_year
)
SELECT
  COALESCE(s.sales_year, r.return_year) AS year,
  COALESCE(s.sales_month, r.return_month) AS month,
  COALESCE(s.birth_year, r.birth_year) AS birth_year,
  COALESCE(s.total_sales, 0) AS total_sales,
  COALESCE(r.total_returns, 0) AS total_returns,
  COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0) AS net_revenue,
  COALESCE(s.total_profit, 0) AS total_profit,
  COALESCE(r.total_loss, 0) AS total_loss,
  COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0) AS net_profit_after_returns,
  COALESCE(s.order_cnt, 0) AS order_cnt,
  COALESCE(r.return_order_cnt, 0) AS return_order_cnt,
  COALESCE(s.cust_cnt, 0) AS cust_cnt
FROM sales_agg s
FULL OUTER JOIN returns_agg r
  ON s.sales_year = r.return_year
  AND s.sales_month = r.return_month
  AND s.birth_year = r.birth_year
ORDER BY year, month, birth_year
