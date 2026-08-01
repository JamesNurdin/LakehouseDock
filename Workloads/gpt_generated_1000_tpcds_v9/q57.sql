WITH
  sales_agg AS (
    SELECT 
      i.i_category AS i_category,
      t.t_hour AS t_hour,
      SUM(cs.cs_net_paid_inc_tax) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt,
      CASE WHEN SUM(cs.cs_net_profit) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price > 100
      AND t.t_hour BETWEEN 8 AND 20
      AND c.c_birth_year >= 1960
    GROUP BY i.i_category, t.t_hour
  ),
  returns_agg AS (
    SELECT 
      i.i_category AS i_category,
      t.t_hour AS t_hour,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(*) AS returns_cnt,
      CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS return_level
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price > 100
      AND t.t_hour BETWEEN 8 AND 20
      AND c.c_birth_year >= 1960
    GROUP BY i.i_category, t.t_hour
  ),
  web_returns_agg AS (
    SELECT 
      i.i_category AS i_category,
      t.t_hour AS t_hour,
      SUM(wr.wr_return_amt_inc_tax) AS total_returns,
      COUNT(*) AS returns_cnt,
      CASE WHEN SUM(wr.wr_return_amt_inc_tax) > 500 THEN 'High' ELSE 'Low' END AS return_level
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_current_price > 100
      AND t.t_hour BETWEEN 8 AND 20
      AND c.c_birth_year >= 1960
    GROUP BY i.i_category, t.t_hour
  ),
  combined_returns AS (
    SELECT i_category, t_hour, total_returns, returns_cnt, return_level FROM returns_agg
    UNION ALL
    SELECT i_category, t_hour, total_returns, returns_cnt, return_level FROM web_returns_agg
  ),
  final_agg AS (
    SELECT 
      s.i_category,
      s.t_hour,
      s.total_sales,
      s.total_profit,
      s.sales_cnt,
      COALESCE(SUM(r.total_returns), 0) AS total_returns,
      COALESCE(SUM(r.returns_cnt), 0) AS total_returns_cnt,
      s.profit_flag,
      CASE WHEN COALESCE(SUM(r.total_returns), 0) > 1000 THEN 'Very High Returns' ELSE 'Normal Returns' END AS return_category
    FROM sales_agg s
    LEFT JOIN combined_returns r
      ON s.i_category = r.i_category AND s.t_hour = r.t_hour
    GROUP BY 
      s.i_category,
      s.t_hour,
      s.total_sales,
      s.total_profit,
      s.sales_cnt,
      s.profit_flag
  )
SELECT 
  i_category,
  t_hour,
  total_sales,
  total_profit,
  total_returns,
  total_returns_cnt,
  profit_flag,
  return_category,
  (total_sales - total_returns) AS net_sales_minus_returns,
  (total_sales - total_returns) / NULLIF(total_sales, 0) * 100 AS net_margin_percent
FROM final_agg
WHERE total_sales > 5000
  AND total_profit > 0
  AND total_returns_cnt > 0
ORDER BY net_margin_percent DESC
LIMIT 100
