WITH sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_sold_date_sk,
    ws.ws_ext_sales_price,
    ws.ws_ext_discount_amt,
    ws.ws_net_profit,
    ws.ws_quantity,
    d.d_year,
    d.d_moy,
    cp.cp_department,
    cd.cd_gender
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_year = 2001
    AND ws.ws_sold_date_sk <= cp.cp_end_date_sk
),
returns AS (
  SELECT
    wr.wr_order_number,
    wr.wr_item_sk,
    wr.wr_returned_date_sk,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    d.d_year,
    d.d_moy
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
  WHERE d.d_year = 2001
    AND wr.wr_returned_date_sk <= cp.cp_end_date_sk
  GROUP BY wr.wr_order_number, wr.wr_item_sk, wr.wr_returned_date_sk, d.d_year, d.d_moy
),
aggregated AS (
  SELECT
    s.cp_department,
    s.d_year,
    s.d_moy AS month,
    SUM(s.ws_ext_sales_price) AS total_sales,
    SUM(s.ws_ext_discount_amt) AS total_discount,
    SUM(s.ws_net_profit) AS total_profit,
    COALESCE(SUM(r.total_return_amount), 0) AS total_returns,
    AVG(CASE WHEN s.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customer_ratio
  FROM sales s
  LEFT JOIN returns r
    ON s.ws_order_number = r.wr_order_number
   AND s.ws_item_sk = r.wr_item_sk
   AND s.ws_sold_date_sk = r.wr_returned_date_sk
  GROUP BY s.cp_department, s.d_year, s.d_moy
)
SELECT
  cp_department,
  d_year,
  month,
  total_sales,
  total_discount,
  total_profit,
  total_returns,
  (total_returns / NULLIF(total_sales, 0)) AS return_rate,
  male_customer_ratio,
  total_profit - total_returns AS net_profit_after_returns,
  LAG(total_profit - total_returns) OVER (PARTITION BY cp_department ORDER BY d_year, month) AS prev_month_net_profit,
  (total_profit - total_returns) - LAG(total_profit - total_returns) OVER (PARTITION BY cp_department ORDER BY d_year, month) AS profit_change_vs_prev_month
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
