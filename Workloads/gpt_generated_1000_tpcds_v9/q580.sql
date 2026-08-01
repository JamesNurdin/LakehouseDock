WITH
  sales_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      d.d_year,
      SUM(ss.ss_net_paid) AS total_net_paid,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      SUM(ss.ss_quantity) AS total_quantity,
      COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 18
      AND d_closed.d_date > DATE '1999-12-31'
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
  ),
  catalog_returns_agg AS (
    SELECT
      cr.cr_call_center_sk,
      cc.cc_name AS call_center_name,
      d.d_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cc.cc_mkt_id = 3
      AND cc.cc_zip = '53951'
      AND d.d_year = 2001
      AND cr.cr_returned_date_sk = 2451041
      AND t.t_hour = 14
    GROUP BY cr.cr_call_center_sk, cc.cc_name, d.d_year
  ),
  web_returns_agg AS (
    SELECT
      NULL AS cr_call_center_sk,
      'Web' AS call_center_name,
      d.d_year,
      SUM(wr.wr_return_amt) AS total_return_amount,
      SUM(wr.wr_return_quantity) AS total_return_qty,
      COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND wr.wr_account_credit > 100
      AND t.t_hour = 14
    GROUP BY d.d_year
  ),
  returns_union AS (
    SELECT
      cr_call_center_sk,
      call_center_name,
      d_year,
      total_return_amount,
      total_return_qty,
      catalog_return_cnt AS return_cnt
    FROM catalog_returns_agg
    UNION ALL
    SELECT
      cr_call_center_sk,
      call_center_name,
      d_year,
      total_return_amount,
      total_return_qty,
      web_return_cnt AS return_cnt
    FROM web_returns_agg
  )
SELECT
  sa.s_store_name,
  sa.d_year AS sales_year,
  sa.total_sales,
  sa.total_profit,
  COALESCE(ru.total_return_amount, 0) AS total_return_amount,
  COALESCE(ru.return_cnt, 0) AS return_cnt,
  (sa.total_sales - COALESCE(ru.total_return_amount, 0)) AS net_sales,
  ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank,
  (SELECT AVG(total_profit) FROM sales_agg) AS avg_yearly_profit
FROM sales_agg sa
LEFT JOIN returns_union ru ON ru.d_year = sa.d_year
WHERE sa.total_profit > (SELECT AVG(total_profit) FROM sales_agg)
ORDER BY sa.d_year, profit_rank
LIMIT 100
