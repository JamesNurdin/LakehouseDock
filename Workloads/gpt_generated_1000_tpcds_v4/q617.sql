WITH sales AS (
       SELECT format_datetime(d.d_date, '%Y-%m') AS period,
              'sales' AS metric_type,
              sum(cs.cs_ext_sales_price) AS amount
       FROM tpcds.catalog_sales cs
       JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
       GROUP BY format_datetime(d.d_date, '%Y-%m')
     ),
     store_ret AS (
       SELECT format_datetime(d.d_date, '%Y-%m') AS period,
              'store_return' AS metric_type,
              sum(sr.sr_return_amt) AS amount
       FROM tpcds.store_returns sr
       JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
       WHERE d.d_year = 2001
       GROUP BY format_datetime(d.d_date, '%Y-%m')
     )
SELECT period,
       metric_type,
       amount
FROM sales
UNION ALL
SELECT period,
       metric_type,
       amount
FROM store_ret
ORDER BY period,
         metric_type,
         amount DESC
LIMIT 100
