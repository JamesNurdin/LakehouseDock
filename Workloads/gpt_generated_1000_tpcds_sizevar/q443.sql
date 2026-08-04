WITH
  sales AS (
    SELECT
      d.d_year,
      d.d_month_seq AS month_seq,
      c.c_customer_id,
      SUM(cs.cs_net_paid) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag
    FROM
      catalog_sales cs
      INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
      INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
      INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
      d.d_year = 2001
    GROUP BY
      d.d_year,
      d.d_month_seq,
      c.c_customer_id
  ),
  returns AS (
    SELECT
      d.d_year,
      d.d_month_seq AS month_seq,
      c.c_customer_id,
      -SUM(cr.cr_return_amount) AS total_sales,
      -SUM(cr.cr_net_loss) AS total_profit,
      CASE WHEN -SUM(cr.cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag
    FROM
      catalog_returns cr
      INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
      INNER JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
      INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE
      d.d_year = 2001
    GROUP BY
      d.d_year,
      d.d_month_seq,
      c.c_customer_id
  ),
  combined AS (
    SELECT * FROM sales
    UNION
    SELECT * FROM returns
  )
SELECT
  combined.d_year,
  combined.month_seq,
  combined.c_customer_id,
  combined.total_sales,
  combined.total_profit,
  combined.profit_flag,
  ROW_NUMBER() OVER (ORDER BY combined.d_year, combined.month_seq, combined.c_customer_id) AS rn
FROM
  combined
ORDER BY
  rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
