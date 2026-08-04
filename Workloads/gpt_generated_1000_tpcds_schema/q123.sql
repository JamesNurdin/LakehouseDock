WITH date_filtered AS (
       SELECT d_date_sk,
              d_year,
              d_fy_quarter_seq,
              d_current_week
       FROM   date_dim
       WHERE  d_year BETWEEN 2000 AND 2002
         AND  d_fy_quarter_seq IN (4, 6, 9)
         AND  d_current_week = 'N'
   ),
   demo_filtered AS (
       SELECT cd_demo_sk,
              cd_gender,
              cd_marital_status,
              cd_purchase_estimate,
              cd_dep_employed_count
       FROM   customer_demographics
       WHERE  cd_purchase_estimate > 3000
         AND  cd_dep_employed_count >= 3
   ),
   site_filtered AS (
       SELECT web_site_sk,
              web_name,
              web_class,
              web_mkt_desc,
              web_open_date_sk
       FROM   web_site
       WHERE  web_class = 'Unknown'
         AND  web_mkt_desc LIKE '%Companies%'
   ),
   intersect_customers AS (
       SELECT wr_returning_customer_sk AS returning_customer_sk
       FROM   web_returns
       WHERE  wr_return_quantity > 1
       INTERSECT
       SELECT wr_returning_customer_sk
       FROM   web_returns
       WHERE  wr_return_amt > 100
   )
SELECT d.d_year,
       cd.cd_gender,
       ws.web_name,
       SUM(wr.wr_refunded_cash) AS total_refunded_cash,
       COUNT(*)                AS returns_cnt,
       RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(wr.wr_refunded_cash) DESC) AS revenue_rank,
       ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(wr.wr_refunded_cash) DESC) AS gender_cash_rank
FROM   web_returns wr
JOIN   date_filtered d
       ON wr.wr_returned_date_sk = d.d_date_sk
JOIN   demo_filtered cd
       ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN   site_filtered ws
       ON ws.web_open_date_sk = d.d_date_sk
JOIN   intersect_customers ic
       ON wr.wr_returning_customer_sk = ic.returning_customer_sk
WHERE  wr.wr_refunded_cash > 500
  AND  wr.wr_return_tax > 0
  AND  wr.wr_fee BETWEEN 0 AND 50
GROUP BY d.d_year,
         cd.cd_gender,
         ws.web_name
ORDER BY total_refunded_cash DESC
LIMIT 100
